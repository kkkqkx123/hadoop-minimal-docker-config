import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import org.apache.hadoop.io.WritableComparable;

/**
 * PageRank节点类，用于存储页面ID、PageRank值和出链列表
 */
public class PageRankNode implements WritableComparable<PageRankNode> {
    private String pageId;        // 页面ID
    private double pageRank;      // PageRank值
    private String[] outLinks;    // 出链列表
    private boolean isNode;       // 标记是否为节点记录（true）或贡献值记录（false）

    // 默认构造函数
    public PageRankNode() {
        this.pageId = "";
        this.pageRank = 0.0;
        this.outLinks = new String[0];
        this.isNode = true;
    }

    // 构造函数
    public PageRankNode(String pageId, double pageRank, String[] outLinks, boolean isNode) {
        this.pageId = pageId;
        this.pageRank = pageRank;
        this.outLinks = outLinks != null ? outLinks : new String[0];
        this.isNode = isNode;
    }

    @Override
    public void write(DataOutput out) throws IOException {
        out.writeUTF(pageId);
        out.writeDouble(pageRank);
        out.writeBoolean(isNode);
        out.writeInt(outLinks.length);
        for (String link : outLinks) {
            out.writeUTF(link);
        }
    }

    @Override
    public void readFields(DataInput in) throws IOException {
        pageId = in.readUTF();
        pageRank = in.readDouble();
        isNode = in.readBoolean();
        int outLinksCount = in.readInt();
        outLinks = new String[outLinksCount];
        for (int i = 0; i < outLinksCount; i++) {
            outLinks[i] = in.readUTF();
        }
    }

    @Override
    public int compareTo(PageRankNode other) {
        return this.pageId.compareTo(other.pageId);
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null || getClass() != obj.getClass()) return false;
        PageRankNode that = (PageRankNode) obj;
        return pageId.equals(that.pageId);
    }

    @Override
    public int hashCode() {
        return pageId.hashCode();
    }

    @Override
    public String toString() {
        if (isNode) {
            StringBuilder sb = new StringBuilder();
            sb.append(pageId).append("\t").append(pageRank);
            if (outLinks.length > 0) {
                sb.append("\t");
                for (int i = 0; i < outLinks.length; i++) {
                    if (i > 0) sb.append(",");
                    sb.append(outLinks[i]);
                }
            }
            return sb.toString();
        } else {
            return pageId + "\t" + pageRank;
        }
    }

    // Getter方法
    public String getPageId() { return pageId; }
    public double getPageRank() { return pageRank; }
    public String[] getOutLinks() { return outLinks; }
    public boolean isNode() { return isNode; }

    // Setter方法
    public void setPageRank(double pageRank) { this.pageRank = pageRank; }
}