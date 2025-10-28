import java.io.IOException;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

/**
 * Mapper类：解析输入数据，创建StudentScore对象作为key，NullWritable作为value
 */
public class Top10Mapper extends Mapper<LongWritable, Text, StudentScore, Text> {
    
    @Override
    protected void map(LongWritable key, Text value, Context context) 
            throws IOException, InterruptedException {
        
        String line = value.toString().trim();
        
        // 跳过空行
        if (line.isEmpty()) {
            return;
        }
        
        try {
            // 解析输入格式：学号,语文成绩,数学成绩,英语成绩
            // 注意：输入数据中可能有制表符分隔，需要处理
            String[] parts = line.split("[\\t,]+");
            
            // 清理每个部分，移除空格和逗号
            String studentId = parts[0].trim();
            int chineseScore = Integer.parseInt(parts[1].trim());
            int mathScore = Integer.parseInt(parts[2].trim());
            int englishScore = Integer.parseInt(parts[3].trim());
            
            // 创建StudentScore对象
            StudentScore studentScore = new StudentScore(studentId, chineseScore, mathScore, englishScore);
            
            // 输出：key为StudentScore对象，value为学号（用于Reducer中识别）
            context.write(studentScore, new Text(studentId));
            
        } catch (Exception e) {
            // 记录解析错误，但继续处理其他行
            System.err.println("Error parsing line: " + line + ", error: " + e.getMessage());
        }
    }
}