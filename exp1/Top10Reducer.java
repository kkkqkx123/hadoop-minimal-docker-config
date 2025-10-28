import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

/**
 * Reducer类：筛选Top10学生成绩
 * 由于Map阶段已经按总分和数学成绩排序，Reducer只需要取前10个
 */
public class Top10Reducer extends Reducer<StudentScore, Text, Text, Text> {
    
    private static final int TOP_N = 10;
    private int count = 0;
    
    @Override
    protected void reduce(StudentScore key, Iterable<Text> values, Context context) 
            throws IOException, InterruptedException {
        
        // 如果已经达到Top10，则跳过
        if (count >= TOP_N) {
            return;
        }
        
        // 遍历所有值（实际上每个key应该只有一个value，因为学号是唯一的）
        for (Text value : values) {
            if (count < TOP_N) {
                // 输出格式：学号 语文：X.0, 数学：Y.0, 英语：Z.0, 总分：W.0
                String output = key.toString();
                context.write(new Text(output), new Text(""));
                count++;
                
                // 输出到控制台用于调试
                System.out.println("Top" + count + ": " + output);
            }
            break; // 只取第一个值，因为学号是唯一的
        }
    }
    
    @Override
    protected void setup(Context context) throws IOException, InterruptedException {
        count = 0;
    }
}