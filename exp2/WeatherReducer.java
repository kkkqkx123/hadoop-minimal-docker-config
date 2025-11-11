import java.io.IOException;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

/**
 * Reducer类：找出每个月的最高温度
 */
public class WeatherReducer extends Reducer<Text, WeatherData, Text, Text> {
    
    @Override
    protected void reduce(Text key, Iterable<WeatherData> values, Context context) 
            throws IOException, InterruptedException {
        
        double maxTemperature = Double.MIN_VALUE;
        WeatherData maxTempData = null;
        
        // 遍历该月的所有天气数据，找出最高温度
        for (WeatherData weatherData : values) {
            if (weatherData.getTemperature() > maxTemperature) {
                maxTemperature = weatherData.getTemperature();
                maxTempData = new WeatherData(
                    weatherData.getDate(), 
                    weatherData.getTime(), 
                    weatherData.getTemperature()
                );
            }
        }
        
        if (maxTempData != null) {
            // 输出格式：月份 最高温度信息
            String output = String.format("最高温度: %.1fc (日期: %s %s)", 
                maxTempData.getTemperature(), 
                maxTempData.getDate(), 
                maxTempData.getTime());
            
            context.write(key, new Text(output));
            
            // 输出到控制台用于调试
            System.out.println(key.toString() + ": " + output);
        }
    }
}