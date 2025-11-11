import java.io.IOException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

/**
 * Mapper类：解析天气数据，提取月份作为key，WeatherData作为value
 */
public class WeatherMapper extends Mapper<LongWritable, Text, Text, WeatherData> {
    
    private static final SimpleDateFormat inputFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    
    @Override
    protected void map(LongWritable key, Text value, Context context) 
            throws IOException, InterruptedException {
        
        String line = value.toString().trim();
        
        // 跳过空行
        if (line.isEmpty()) {
            return;
        }
        
        try {
            // 解析输入格式：日期时间 温度
            // 格式：2015-01-01 13:46:57	3.5c
            String[] parts = line.split("\\s+");
            
            if (parts.length < 2) {
                return; // 格式不正确
            }
            
            // 提取日期和时间
            String dateTime = parts[0] + " " + parts[1];
            
            // 提取温度（移除'c'后缀）
            String tempPart = parts[2].replace("c", "");
            double temperature = Double.parseDouble(tempPart);
            
            // 解析日期
            Date date = inputFormat.parse(dateTime);
            SimpleDateFormat monthFormat = new SimpleDateFormat("yyyy-MM");
            String month = monthFormat.format(date);
            
            // 创建WeatherData对象
            WeatherData weatherData = new WeatherData(parts[0], parts[1], temperature);
            
            // 输出：key为月份，value为WeatherData对象
            context.write(new Text(month), weatherData);
            
        } catch (Exception e) {
            // 记录解析错误，但继续处理其他行
            System.err.println("Error parsing line: " + line + ", error: " + e.getMessage());
        }
    }
}