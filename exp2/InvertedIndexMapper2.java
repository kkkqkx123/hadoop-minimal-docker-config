import java.io.IOException;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

/**
 * 倒排索引第二轮Mapper类：解析第一轮输出，构建"词->文档"映射
 * 输入格式：word--docName\tcount
 * 输出格式：word\tdocName-->count
 */
public class InvertedIndexMapper2 extends Mapper<LongWritable, Text, Text, Text> {
    
    @Override
    protected void map(LongWritable key, Text value, Context context) 
            throws IOException, InterruptedException {
        
        String line = value.toString().trim();
        
        // 跳过空行
        if (line.isEmpty()) {
            return;
        }
        
        try {
            // 解析输入格式：word--docName\tcount
            String[] parts = line.split("\t");
            if (parts.length == 2) {
                String wordDocKey = parts[0].trim();
                String count = parts[1].trim();
                
                // 解析word--docName
                String[] wordDocParts = wordDocKey.split("--");
                if (wordDocParts.length == 2) {
                    String word = wordDocParts[0].trim();
                    String docName = wordDocParts[1].trim();
                    
                    // 输出：key为词，value为"docName-->count"
                    String outputValue = docName + "-->" + count;
                    context.write(new Text(word), new Text(outputValue));
                }
            }
            
        } catch (Exception e) {
            // 记录解析错误，但继续处理其他行
            System.err.println("Error parsing line: " + line + ", error: " + e.getMessage());
        }
    }
}