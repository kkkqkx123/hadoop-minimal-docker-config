import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

/**
 * 倒排索引第二轮Reducer类：合并同一词的所有文档信息
 * 输入：word\t docName-->count 格式
 * 输出：word\t doc1-->count1 doc2-->count2 ...
 */
public class InvertedIndexReducer2 extends Reducer<Text, Text, Text, Text> {
    
    @Override
    protected void reduce(Text key, Iterable<Text> values, Context context) 
            throws IOException, InterruptedException {
        
        try {
            // 收集所有文档信息
            List<String> docInfoList = new ArrayList<>();
            for (Text value : values) {
                String docInfo = value.toString().trim();
                if (!docInfo.isEmpty()) {
                    docInfoList.add(docInfo);
                }
            }
            
            // 按文档名排序（可选，但有助于输出的一致性）
            Collections.sort(docInfoList);
            
            // 合并所有文档信息
            StringBuilder mergedInfo = new StringBuilder();
            for (int i = 0; i < docInfoList.size(); i++) {
                if (i > 0) {
                    mergedInfo.append(" ");
                }
                mergedInfo.append(docInfoList.get(i));
            }
            
            // 输出结果
            context.write(key, new Text(mergedInfo.toString()));
            
        } catch (Exception e) {
            // 记录错误，但继续处理
            System.err.println("Error in reduce: " + e.getMessage());
        }
    }
}