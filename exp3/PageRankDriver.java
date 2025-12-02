import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;

/**
 * PageRank Driver类：配置和运行PageRank MapReduce作业
 */
public class PageRankDriver {
    
    // 自定义计数器，用于检查收敛
    public static enum Counter {
        CONVERGENCE
    }
    
    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.err.println("Usage: PageRankDriver <input path> <output path> [max iterations]");
            System.exit(-1);
        }
        
        String inputPath = args[0];
        String outputPath = args[1];
        int maxIterations = 10; // 默认最大迭代次数
        
        if (args.length >= 3) {
            maxIterations = Integer.parseInt(args[2]);
        }
        
        Configuration conf = new Configuration();
        
        for (int iteration = 0; iteration < maxIterations; iteration++) {
            System.out.println("Iteration " + (iteration + 1) + " of " + maxIterations);
            
            // 创建Job实例
            Job job = Job.getInstance(conf, "PageRank Iteration " + (iteration + 1));
            job.setJarByClass(PageRankDriver.class);
            
            // 设置Mapper和Reducer类
            job.setMapperClass(PageRankMapper.class);
            job.setReducerClass(PageRankReducer.class);
            
            // 设置输出key和value类型
            job.setMapOutputKeyClass(Text.class);
            job.setMapOutputValueClass(PageRankNode.class);
            job.setOutputKeyClass(Text.class);
            job.setOutputValueClass(Text.class);
            
            // 设置输入输出格式
            job.setInputFormatClass(TextInputFormat.class);
            job.setOutputFormatClass(TextOutputFormat.class);
            
            // 设置输入路径
            if (iteration == 0) {
                // 第一次迭代使用原始输入
                FileInputFormat.addInputPath(job, new Path(inputPath));
            } else {
                // 后续迭代使用前一次的输出
                FileInputFormat.addInputPath(job, new Path(outputPath + "/iteration" + iteration));
            }
            
            // 设置输出路径
            String currentOutputPath = outputPath + "/iteration" + (iteration + 1);
            FileOutputFormat.setOutputPath(job, new Path(currentOutputPath));
            
            // 等待作业完成
            boolean success = job.waitForCompletion(true);
            if (!success) {
                System.err.println("Job failed at iteration " + (iteration + 1));
                System.exit(1);
            }
            
            // 检查收敛性
            long convergenceCount = job.getCounters().findCounter(Counter.CONVERGENCE).getValue();
            if (convergenceCount == 0) {
                System.out.println("Converged at iteration " + (iteration + 1));
                break;
            }
            
            System.out.println("Convergence count: " + convergenceCount);
        }
        
        System.out.println("PageRank calculation completed!");
        System.exit(0);
    }
}