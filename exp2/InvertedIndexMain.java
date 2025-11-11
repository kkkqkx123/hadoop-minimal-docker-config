import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;

/**
 * 倒排索引主类：协调两轮MapReduce作业
 * 第一轮：统计每个词在每个文档中的出现次数
 * 第二轮：合并同一词在所有文档中的信息
 */
public class InvertedIndexMain {
    
    private static final String HDFS_INPUT = "/exp2/input/";
    private static final String HDFS_TEMP = "/exp2/temp/";
    private static final String HDFS_OUTPUT = "/exp2/output/";
    
    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            System.err.println("Usage: InvertedIndexMain <local input path>");
            System.exit(-1);
        }
        
        String localInputPath = args[0];
        boolean success = false;
        
        try {
            System.out.println("=== 倒排索引MapReduce处理开始 ===");
            
            // 清理HDFS上的输出目录
            cleanupHDFS();
            
            // 第一步：复制本地文件到HDFS
            System.out.println("第一步：复制本地文件到HDFS...");
            copyLocalToHDFS(localInputPath);
            
            // 第二步：第一轮MapReduce
            System.out.println("第二步：执行第一轮MapReduce（统计词频）...");
            success = runFirstJob();
            if (!success) {
                System.err.println("第一轮MapReduce失败！");
                return;
            }
            
            // 第三步：第二轮MapReduce
            System.out.println("第三步：执行第二轮MapReduce（合并文档信息）...");
            success = runSecondJob();
            if (!success) {
                System.err.println("第二轮MapReduce失败！");
                return;
            }
            
            // 第四步：下载结果到本地
            System.out.println("第四步：下载结果到本地...");
            copyHDFSToLocal();
            
            System.out.println("=== 倒排索引MapReduce处理完成 ===");
            System.out.println("结果文件保存在：output/ 目录下");
            
        } catch (Exception e) {
            System.err.println("处理过程中出现错误：" + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
        
        System.exit(success ? 0 : 1);
    }
    
    /**
     * 清理HDFS上的输出目录
     */
    private static void cleanupHDFS() throws Exception {
        Configuration conf = new Configuration();
        org.apache.hadoop.fs.FileSystem fs = org.apache.hadoop.fs.FileSystem.get(conf);
        
        // 删除输出目录
        if (fs.exists(new Path(HDFS_TEMP))) {
            fs.delete(new Path(HDFS_TEMP), true);
            System.out.println("已清理临时目录：" + HDFS_TEMP);
        }
        if (fs.exists(new Path(HDFS_OUTPUT))) {
            fs.delete(new Path(HDFS_OUTPUT), true);
            System.out.println("已清理输出目录：" + HDFS_OUTPUT);
        }
        
        fs.close();
    }
    
    /**
     * 复制本地文件到HDFS
     */
    private static void copyLocalToHDFS(String localPath) throws Exception {
        Configuration conf = new Configuration();
        org.apache.hadoop.fs.FileSystem fs = org.apache.hadoop.fs.FileSystem.get(conf);
        org.apache.hadoop.fs.Path hdfsInputPath = new Path(HDFS_INPUT);
        
        // 创建输入目录
        if (!fs.exists(hdfsInputPath)) {
            fs.mkdirs(hdfsInputPath);
        }
        
        // 复制文件
        org.apache.hadoop.fs.Path localFile = new org.apache.hadoop.fs.Path(localPath);
        org.apache.hadoop.fs.Path hdfsFile = new org.apache.hadoop.fs.Path(HDFS_INPUT + localFile.getName());
        fs.copyFromLocalFile(false, true, localFile, hdfsFile);
        
        System.out.println("已复制文件到HDFS：" + hdfsFile.toString());
        fs.close();
    }
    
    /**
     * 执行第一轮MapReduce作业
     */
    private static boolean runFirstJob() throws Exception {
        Configuration conf = new Configuration();
        
        // 创建Job实例
        Job job = Job.getInstance(conf, "Inverted Index Step1");
        job.setJarByClass(InvertedIndexMain.class);
        
        // 设置Mapper和Reducer类
        job.setMapperClass(InvertedIndexMapper.class);
        job.setReducerClass(InvertedIndexReducer.class);
        
        // 设置输出key和value类型
        job.setMapOutputKeyClass(WordDocCount.class);
        job.setMapOutputValueClass(Text.class);
        job.setOutputKeyClass(WordDocCount.class);
        job.setOutputValueClass(Text.class);
        
        // 设置输入输出格式
        job.setInputFormatClass(TextInputFormat.class);
        job.setOutputFormatClass(TextOutputFormat.class);
        
        // 设置输入输出路径
        FileInputFormat.addInputPath(job, new Path(HDFS_INPUT));
        FileOutputFormat.setOutputPath(job, new Path(HDFS_TEMP));
        
        // 等待作业完成
        return job.waitForCompletion(true);
    }
    
    /**
     * 执行第二轮MapReduce作业
     */
    private static boolean runSecondJob() throws Exception {
        Configuration conf = new Configuration();
        
        // 创建Job实例
        Job job = Job.getInstance(conf, "Inverted Index Step2");
        job.setJarByClass(InvertedIndexMain.class);
        
        // 设置Mapper和Reducer类
        job.setMapperClass(InvertedIndexMapper2.class);
        job.setReducerClass(InvertedIndexReducer2.class);
        
        // 设置输出key和value类型
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        
        // 设置输入输出格式
        job.setInputFormatClass(TextInputFormat.class);
        job.setOutputFormatClass(TextOutputFormat.class);
        
        // 设置输入输出路径
        FileInputFormat.addInputPath(job, new Path(HDFS_TEMP));
        FileOutputFormat.setOutputPath(job, new Path(HDFS_OUTPUT));
        
        // 等待作业完成
        return job.waitForCompletion(true);
    }
    
    /**
     * 下载HDFS结果到本地
     */
    private static void copyHDFSToLocal() throws Exception {
        Configuration conf = new Configuration();
        org.apache.hadoop.fs.FileSystem fs = org.apache.hadoop.fs.FileSystem.get(conf);
        
        // 创建本地输出目录
        java.io.File localOutputDir = new java.io.File("output");
        if (!localOutputDir.exists()) {
            localOutputDir.mkdirs();
        }
        
        // 下载结果文件
        org.apache.hadoop.fs.Path hdfsOutputPath = new Path(HDFS_OUTPUT);
        if (fs.exists(hdfsOutputPath)) {
            org.apache.hadoop.fs.FileStatus[] files = fs.listStatus(hdfsOutputPath);
            for (org.apache.hadoop.fs.FileStatus file : files) {
                if (!file.isDirectory()) {
                    String fileName = file.getPath().getName();
                    if (fileName.startsWith("part-")) {
                        org.apache.hadoop.fs.Path localFile = new org.apache.hadoop.fs.Path("output/" + fileName);
                        fs.copyToLocalFile(file.getPath(), localFile);
                        System.out.println("已下载结果文件：" + localFile.toString());
                    }
                }
            }
        }
        
        fs.close();
    }
}