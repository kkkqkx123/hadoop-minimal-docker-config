import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

/**
 * 自定义WritableComparable类，用于存储学生成绩信息并实现排序逻辑
 * 排序规则：总分从高到低，总分相同则按数学成绩从高到低
 */
public class StudentScore implements WritableComparable<StudentScore> {
    private String studentId;      // 学号
    private int chineseScore;      // 语文成绩
    private int mathScore;         // 数学成绩
    private int englishScore;      // 英语成绩
    private int totalScore;        // 总分

    // 默认构造函数
    public StudentScore() {
        this.studentId = "";
        this.chineseScore = 0;
        this.mathScore = 0;
        this.englishScore = 0;
        this.totalScore = 0;
    }

    // 带参构造函数
    public StudentScore(String studentId, int chineseScore, int mathScore, int englishScore) {
        this.studentId = studentId;
        this.chineseScore = chineseScore;
        this.mathScore = mathScore;
        this.englishScore = englishScore;
        this.totalScore = chineseScore + mathScore + englishScore;
    }

    @Override
    public void write(DataOutput out) throws IOException {
        out.writeUTF(studentId);
        out.writeInt(chineseScore);
        out.writeInt(mathScore);
        out.writeInt(englishScore);
        out.writeInt(totalScore);
    }

    @Override
    public void readFields(DataInput in) throws IOException {
        this.studentId = in.readUTF();
        this.chineseScore = in.readInt();
        this.mathScore = in.readInt();
        this.englishScore = in.readInt();
        this.totalScore = in.readInt();
    }

    @Override
    public int compareTo(StudentScore other) {
        // 先按总分降序排序
        if (this.totalScore != other.totalScore) {
            return Integer.compare(other.totalScore, this.totalScore); // 降序
        }
        // 总分相同则按数学成绩降序排序
        return Integer.compare(other.mathScore, this.mathScore); // 降序
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null || getClass() != obj.getClass()) return false;
        StudentScore that = (StudentScore) obj;
        return chineseScore == that.chineseScore &&
               mathScore == that.mathScore &&
               englishScore == that.englishScore &&
               totalScore == that.totalScore &&
               studentId.equals(that.studentId);
    }

    @Override
    public int hashCode() {
        int result = studentId.hashCode();
        result = 31 * result + chineseScore;
        result = 31 * result + mathScore;
        result = 31 * result + englishScore;
        result = 31 * result + totalScore;
        return result;
    }

    @Override
    public String toString() {
        return studentId + " 语文：" + chineseScore + ".0, 数学：" + mathScore + ".0, 英语：" + englishScore + ".0, 总分：" + totalScore + ".0";
    }

    // Getter方法
    public String getStudentId() { return studentId; }
    public int getChineseScore() { return chineseScore; }
    public int getMathScore() { return mathScore; }
    public int getEnglishScore() { return englishScore; }
    public int getTotalScore() { return totalScore; }
}