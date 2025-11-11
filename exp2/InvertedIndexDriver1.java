import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;

/**
 * 倒排索引第一轮MapReduce作业Driver
 * 功能：统计每个词在每个文档中的出现次数
 * 输入：doc1.txt, doc2.txt, doc3.txt
 * 输出：word--docName\tcount
 */
public class InvertedIndexDriver1 {
    
    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: InvertedIndexDriver1 <input path> <output path>");
            System.exit(-1);
        }
        
        Configuration conf = new Configuration();
        
        // 创建Job实例
        Job job = Job.getInstance(conf, "Inverted Index Step1");
        job.setJarByClass(InvertedIndexDriver1.class);
        
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
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        
        // 等待作业完成
        boolean success = job.waitForCompletion(true);
        System.exit(success ? 0 : 1);
    }
}