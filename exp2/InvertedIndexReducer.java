import java.io.IOException;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

/**
 * 倒排索引Reducer类：第一轮处理，统计词频
 * 输出格式：word--docName\tcount
 */
public class InvertedIndexReducer extends Reducer<WordDocCount, Text, WordDocCount, Text> {
    
    @Override
    protected void reduce(WordDocCount key, Iterable<Text> values, Context context) 
            throws IOException, InterruptedException {
        
        try {
            // 统计词频（对于同一word和docName的组合，统计出现次数）
            int totalCount = 0;
            for (Text value : values) {
                totalCount++;
            }
            
            // 设置计数并输出
            WordDocCount outputKey = new WordDocCount(key.getWord(), key.getDocName(), totalCount);
            context.write(outputKey, new Text(""));
            
        } catch (Exception e) {
            // 记录错误，但继续处理
            System.err.println("Error in reduce: " + e.getMessage());
        }
    }
}