import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import org.apache.hadoop.io.WritableComparable;

/**
 * 自定义Writable类，用于存储"词-文档"的键值对及计数
 * 排序规则：先按词排序，词相同则按文档名排序
 */
public class WordDocCount implements WritableComparable<WordDocCount> {
    private String word;      // 词
    private String docName;   // 文档名
    private int count;        // 计数

    // 默认构造函数
    public WordDocCount() {
        this.word = "";
        this.docName = "";
        this.count = 0;
    }

    // 带参构造函数
    public WordDocCount(String word, String docName, int count) {
        this.word = word;
        this.docName = docName;
        this.count = count;
    }

    @Override
    public void write(DataOutput out) throws IOException {
        out.writeUTF(word);
        out.writeUTF(docName);
        out.writeInt(count);
    }

    @Override
    public void readFields(DataInput in) throws IOException {
        this.word = in.readUTF();
        this.docName = in.readUTF();
        this.count = in.readInt();
    }

    @Override
    public int compareTo(WordDocCount other) {
        // 先按词排序
        int wordCompare = this.word.compareTo(other.word);
        if (wordCompare != 0) {
            return wordCompare;
        }
        // 词相同则按文档名排序
        return this.docName.compareTo(other.docName);
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null || getClass() != obj.getClass()) return false;
        WordDocCount that = (WordDocCount) obj;
        return word.equals(that.word) &&
               docName.equals(that.docName) &&
               count == that.count;
    }

    @Override
    public int hashCode() {
        int result = word.hashCode();
        result = 31 * result + docName.hashCode();
        result = 31 * result + count;
        return result;
    }

    @Override
    public String toString() {
        return word + "--" + docName + "\t" + count;
    }

    // Getter方法
    public String getWord() { return word; }
    public String getDocName() { return docName; }
    public int getCount() { return count; }
    
    // Setter方法
    public void setWord(String word) { this.word = word; }
    public void setDocName(String docName) { this.docName = docName; }
    public void setCount(int count) { this.count = count; }
}