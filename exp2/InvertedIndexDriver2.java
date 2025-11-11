import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;

/**
 * 倒排索引第二轮MapReduce作业Driver
 * 功能：合并同一词在所有文档中的信息
 * 输入：word--docName\tcount
 * 输出：word\t doc1-->count1 doc2-->count2 ...
 */
public class InvertedIndexDriver2 {
    
    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: InvertedIndexDriver2 <input path> <output path>");
            System.exit(-1);
        }
        
        Configuration conf = new Configuration();
        
        // 创建Job实例
        Job job = Job.getInstance(conf, "Inverted Index Step2");
        job.setJarByClass(InvertedIndexDriver2.class);
        
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
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        
        // 等待作业完成
        boolean success = job.waitForCompletion(true);
        System.exit(success ? 0 : 1);
    }
}