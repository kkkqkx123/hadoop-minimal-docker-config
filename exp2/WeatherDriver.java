import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;

/**
 * 主类：配置和运行天气数据分析的MapReduce作业
 * 功能：找出每个月的最高温度
 */
public class WeatherDriver {
    
    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: WeatherDriver <input path> <output path>");
            System.err.println("Example: WeatherDriver /input/weather.txt /output/weather");
            System.exit(-1);
        }
        
        Configuration conf = new Configuration();
        
        // 创建Job实例
        Job job = Job.getInstance(conf, "Weather Data Analysis - Max Temperature per Month");
        job.setJarByClass(WeatherDriver.class);
        
        // 设置Mapper和Reducer类
        job.setMapperClass(WeatherMapper.class);
        job.setReducerClass(WeatherReducer.class);
        
        // 设置输出key和value类型
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(WeatherData.class);
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
        
        System.out.println("Starting Weather Data Analysis Job...");
        System.out.println("Input: " + args[0]);
        System.out.println("Output: " + args[1]);
        
        // 等待作业完成
        boolean success = job.waitForCompletion(true);
        
        if (success) {
            System.out.println("Weather Data Analysis Job completed successfully!");
        } else {
            System.err.println("Weather Data Analysis Job failed!");
        }
        
        System.exit(success ? 0 : 1);
    }
}