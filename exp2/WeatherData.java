import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import org.apache.hadoop.io.WritableComparable;

/**
 * 自定义WritableComparable类，用于存储天气数据信息
 * 包含日期和温度信息
 */
public class WeatherData implements WritableComparable<WeatherData> {
    private String date;      // 日期 (格式: 2015-01-01)
    private String time;      // 时间 (格式: 13:46:57)
    private double temperature; // 温度 (单位: 摄氏度)

    // 默认构造函数
    public WeatherData() {
        this.date = "";
        this.time = "";
        this.temperature = 0.0;
    }

    // 带参构造函数
    public WeatherData(String date, String time, double temperature) {
        this.date = date;
        this.time = time;
        this.temperature = temperature;
    }

    @Override
    public void write(DataOutput out) throws IOException {
        out.writeUTF(date);
        out.writeUTF(time);
        out.writeDouble(temperature);
    }

    @Override
    public void readFields(DataInput in) throws IOException {
        this.date = in.readUTF();
        this.time = in.readUTF();
        this.temperature = in.readDouble();
    }

    @Override
    public int compareTo(WeatherData other) {
        // 按温度降序排序
        return Double.compare(other.temperature, this.temperature);
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null || getClass() != obj.getClass()) return false;
        WeatherData that = (WeatherData) obj;
        return Double.compare(that.temperature, temperature) == 0 &&
               date.equals(that.date) &&
               time.equals(that.time);
    }

    @Override
    public int hashCode() {
        int result;
        long temp;
        result = date.hashCode();
        result = 31 * result + time.hashCode();
        temp = Double.doubleToLongBits(temperature);
        result = 31 * result + (int) (temp ^ (temp >>> 32));
        return result;
    }

    @Override
    public String toString() {
        return date + " " + time + " " + temperature + "c";
    }

    // Getter方法
    public String getDate() { return date; }
    public String getTime() { return time; }
    public double getTemperature() { return temperature; }
    
    // 获取月份 (格式: 2015-01)
    public String getMonth() {
        if (date.length() >= 7) {
            return date.substring(0, 7);
        }
        return "";
    }
}