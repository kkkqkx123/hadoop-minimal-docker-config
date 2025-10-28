import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;

/**
 * 主类：配置和运行学生成绩Top10排序的MapReduce作业
 */
public class Top10Driver {
    
    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: Top10Driver <input path> <output path>");
            System.exit(-1);
        }
        
        Configuration conf = new Configuration();
        
        // 创建Job实例
        Job job = Job.getInstance(conf, "Student Score Top10");
        job.setJarByClass(Top10Driver.class);
        
        // 设置Mapper和Reducer类
        job.setMapperClass(Top10Mapper.class);
        job.setReducerClass(Top10Reducer.class);
        
        // 设置输出key和value类型
        job.setMapOutputKeyClass(StudentScore.class);
        job.setMapOutputValueClass(Text.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        
        // 设置输入输出格式
        job.setInputFormatClass(TextInputFormat.class);
        job.setOutputFormatClass(TextOutputFormat.class);
        
        // 设置Reducer数量为1，确保全局排序
        job.setNumReduceTasks(1);
        
        // 设置输入输出路径
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        
        // 等待作业完成
        boolean success = job.waitForCompletion(true);
        System.exit(success ? 0 : 1);
    }
}