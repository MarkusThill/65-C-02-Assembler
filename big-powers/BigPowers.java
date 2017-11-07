import java.math.BigInteger;

public class BigPowers {
	public static BigInteger bigPower(int base, int exp) {
		BigInteger result = new BigInteger(base + "");
		return result.pow(exp);
	}

	public static void main(String[] args) {
		int base = 0x29;
		int exp=0xBF;
		System.out.println(base+"^"+exp+"=");
		String result = bigPower(base, exp).toString(16);
		System.out.println("\t"+result);
		System.out.println("Number of Bytes: " + (result.length()/2+result.length()%2));
	}
}
