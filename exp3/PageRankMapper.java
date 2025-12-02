import java.io.IOException;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

/**
 * PageRank Mapper类
 * 输入：页面ID和页面信息（包含出链）
 * 输出：页面节点和贡献值
 */
public class PageRankMapper extends Mapper<LongWritable, Text, Text, PageRankNode> {
    
    private static final double DAMPING_FACTOR = 0.85;
    
    @Override
    protected void map(LongWritable key, Text value, Context context) 
            throws IOException, InterruptedException {
        
        String line = value.toString().trim();
        
        // 跳过空行
        if (line.isEmpty()) {
            return;
        }
        
        try {
            // 解析输入格式：pageId\tpageRank\toutLink1,outLink2,...
            // 或者：pageId\tpageTitle（初始格式）
            String[] parts = line.split("\t");
            
            if (parts.length < 2) {
                return;
            }
            
            String pageId = parts[0].trim();
            
            // 检查是否是初始数据（只有页面标题）
            if (parts.length == 2) {
                // 初始数据，设置PageRank为1.0，没有出链
                PageRankNode node = new PageRankNode(pageId, 1.0, new String[0], true);
                context.write(new Text(pageId), node);
                return;
            }
            
            // 解析PageRank值和出链
            double pageRank = Double.parseDouble(parts[1].trim());
            String[] outLinks = new String[0];
            
            if (parts.length >= 3 && !parts[2].trim().isEmpty()) {
                outLinks = parts[2].trim().split(",");
            }
            
            // 输出当前节点信息
            PageRankNode currentNode = new PageRankNode(pageId, pageRank, outLinks, true);
            context.write(new Text(pageId), currentNode);
            
            // 如果有出链，计算并输出贡献值
            if (outLinks.length > 0) {
                double contribution = pageRank * DAMPING_FACTOR / outLinks.length;
                
                for (String outLink : outLinks) {
                    if (!outLink.trim().isEmpty()) {
                        PageRankNode contributionNode = new PageRankNode(outLink.trim(), contribution, new String[0], false);
                        context.write(new Text(outLink.trim()), contributionNode);
                    }
                }
            }
            
        } catch (Exception e) {
            // 记录解析错误，但继续处理其他行
            System.err.println("Error parsing line: " + line + ", error: " + e.getMessage());
        }
    }
}