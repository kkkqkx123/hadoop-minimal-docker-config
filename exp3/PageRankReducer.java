import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

/**
 * PageRank Reducer类
 * 输入：页面ID对应的节点信息和贡献值列表
 * 输出：更新后的页面节点
 */
public class PageRankReducer extends Reducer<Text, PageRankNode, Text, Text> {
    
    private static final double DAMPING_FACTOR = 0.85;
    private static final double TELEPORTATION = 0.15;
    private static final double CONVERGENCE_THRESHOLD = 0.001;
    
    @Override
    protected void reduce(Text key, Iterable<PageRankNode> values, Context context) 
            throws IOException, InterruptedException {
        
        double sumContributions = 0.0;
        double oldPageRank = 0.0;
        String[] outLinks = new String[0];
        boolean hasNode = false;
        
        // 遍历所有值，收集贡献值和原始节点信息
        for (PageRankNode node : values) {
            if (node.isNode()) {
                // 这是原始节点信息
                oldPageRank = node.getPageRank();
                outLinks = node.getOutLinks();
                hasNode = true;
            } else {
                // 这是贡献值
                sumContributions += node.getPageRank();
            }
        }
        
        // 如果没有找到节点信息，说明这是一个新页面（被其他页面引用但没有出链）
        if (!hasNode) {
            oldPageRank = 1.0; // 初始PageRank值
        }
        
        // 计算新的PageRank值
        double newPageRank = TELEPORTATION + DAMPING_FACTOR * sumContributions;
        
        // 检查收敛性
        double diff = Math.abs(newPageRank - oldPageRank);
        if (diff > CONVERGENCE_THRESHOLD) {
            context.getCounter(PageRankDriver.Counter.CONVERGENCE).increment(1);
        }
        
        // 构建输出
        StringBuilder output = new StringBuilder();
        output.append(key.toString()).append("\t").append(newPageRank);
        
        // 添加出链信息
        if (outLinks.length > 0) {
            output.append("\t");
            for (int i = 0; i < outLinks.length; i++) {
                if (i > 0) output.append(",");
                output.append(outLinks[i]);
            }
        }
        
        context.write(key, new Text(output.toString()));
    }
}