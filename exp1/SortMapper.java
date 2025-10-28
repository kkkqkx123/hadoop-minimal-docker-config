import java.io.IOException;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

/**
 * Mapper类：解析输入数据，将字母作为key，数字作为value
 * 输入格式：字母\t数字
 * 输出格式：key=字母，value=数字
 */
public class SortMapper extends Mapper<LongWritable, Text, Text, Text> {
    
    @Override
    protected void map(LongWritable key, Text value, Context context) 
            throws IOException, InterruptedException {
        
        String line = value.toString().trim();
        
        // 跳过空行
        if (line.isEmpty()) {
            return;
        }
        
        try {
            // 解析输入格式：字母\t数字
            String[] parts = line.split("\\t");
            
            if (parts.length >= 2) {
                String letter = parts[0].trim();
                String number = parts[1].trim();
                
                // 输出：key为字母，value为数字
                context.write(new Text(letter), new Text(number));
            }
            
        } catch (Exception e) {
            // 记录解析错误，但继续处理其他行
            System.err.println("Error parsing line: " + line + ", error: " + e.getMessage());
        }
    }
}