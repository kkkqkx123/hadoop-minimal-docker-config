import java.io.IOException;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;

/**
 * 倒排索引Mapper类：提取文档中的词，构建"词-文档"键值对
 */
public class InvertedIndexMapper extends Mapper<LongWritable, Text, WordDocCount, Text> {
    
    @Override
    protected void map(LongWritable key, Text value, Context context) 
            throws IOException, InterruptedException {
        
        String line = value.toString().trim();
        
        // 跳过空行
        if (line.isEmpty()) {
            return;
        }
        
        try {
            // 获取输入文件路径信息
            FileSplit fileSplit = (FileSplit) context.getInputSplit();
            String fileName = fileSplit.getPath().getName();
            
            // 解析输入格式：词\t文档内容
            String[] parts = line.split("\t");
            if (parts.length >= 1) {
                String word = parts[0].trim();
                
                // 构建输出键：word--docName
                String outputKey = word + "--" + fileName;
                WordDocCount wordDocCount = new WordDocCount(word, fileName, 1);
                
                // 输出：key为WordDocCount对象，value为空（第一轮只需要统计）
                context.write(wordDocCount, new Text(""));
            }
            
        } catch (Exception e) {
            // 记录解析错误，但继续处理其他行
            System.err.println("Error parsing line: " + line + ", error: " + e.getMessage());
        }
    }
}