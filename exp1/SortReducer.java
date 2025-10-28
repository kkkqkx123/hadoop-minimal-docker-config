import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

/**
 * Reducer类：对每个字母对应的数字进行降序排序
 * 输入：key=字母，values=该字母对应的所有数字
 * 输出：key=字母，value=降序排序后的数字列表
 */
public class SortReducer extends Reducer<Text, Text, Text, Text> {
    
    @Override
    protected void reduce(Text key, Iterable<Text> values, Context context) 
            throws IOException, InterruptedException {
        
        // 收集所有数字
        List<Integer> numbers = new ArrayList<>();
        
        for (Text value : values) {
            try {
                int number = Integer.parseInt(value.toString());
                numbers.add(number);
            } catch (NumberFormatException e) {
                System.err.println("Invalid number format: " + value.toString());
            }
        }
        
        // 对数字进行排序（降序）
        Collections.sort(numbers, Collections.reverseOrder());
        
        // 构建输出字符串
        StringBuilder sortedNumbers = new StringBuilder();
        for (int i = 0; i < numbers.size(); i++) {
            if (i > 0) {
                sortedNumbers.append(", ");
            }
            sortedNumbers.append(numbers.get(i));
        }
        
        // 输出：字母 -> 排序后的数字列表
        context.write(key, new Text(sortedNumbers.toString()));
        
        // 输出到控制台用于调试
        System.out.println("Letter " + key.toString() + ": " + sortedNumbers.toString());
    }
}