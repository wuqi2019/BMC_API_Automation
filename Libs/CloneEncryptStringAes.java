//package com.hikcreate.edl.common.sdk.util;;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;

/**
 * AES 加密解密
 *
 * @author zhaodong5
 * @date 2019/8/9 14:23
 */
public class CloneEncryptStringAes {

    private static Charset DEFAULT_CHARSET = StandardCharsets.UTF_8;
    private static String KEY_CIPHER = "AES/ECB/PKCS5Padding";
    private static String KEY_CHARSET = "UTF-8";
    private static String KEY_AES = "AES";
    private static String[] hexDigIts = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
            "a", "b", "c", "d", "e", "f"};

    /**
     * 加密
     *
     * @param data 需要加密的内容
     * @return
     */
    public static String encryptAes(String data) {
        if (isEmpty(data)) {
            return null;
        }
        try {
            String encoded = "HIKEDL@#";
            MessageDigest md = MessageDigest.getInstance("MD5");
            String password = byteArrayToHexString(md.digest(encoded.getBytes("UTF-8")));

            byte[] enCodeFormat = password.getBytes(KEY_CHARSET);
            //动态根据password的长度来选择128还是256bit
            SecretKeySpec keySpec = new SecretKeySpec(enCodeFormat, KEY_AES);
            byte[] bytes = data.getBytes(KEY_CHARSET);
            Cipher cipher = Cipher.getInstance(KEY_CIPHER);
            cipher.init(cipher.ENCRYPT_MODE, keySpec);
            //将加密并编码后的内容解码成字节数组
            byte[] result = cipher.doFinal(bytes);
            return encodeToString(result);
        } catch (Exception e) {
            System.out.println("Encrypt Data Error,msg={" + e + "}");
        }

        return null;
    }

    /**
     * MD5加密
     *
     * @param origin      字符
     * @param charsetName 编码
     * @return MD5加密串
     */
    public static String md5Encode(String origin, String charsetName) {
        String encoded = origin;
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            if (null == charsetName || "".equals(charsetName)) {
                encoded = byteArrayToHexString(md.digest(encoded.getBytes()));
            } else {
                encoded = byteArrayToHexString(md.digest(encoded.getBytes(charsetName)));
            }
        } catch (Exception e) {
        }
        return encoded;
    }

    public static String byteArrayToHexString(byte b[]) {
        StringBuilder sb = new StringBuilder();
        for (byte b1 : b) {
            sb.append(byteToHexString(b1));
        }
        return sb.toString();
    }

    public static String byteToHexString(byte b) {
        int n = b;
        if (n < 0) {
            n += 256;
        }
        int d1 = n / 16;
        int d2 = n % 16;
        return hexDigIts[d1] + hexDigIts[d2];
    }

    public static void main(String[] args) throws Exception {
        System.out.println(encryptAes("123456"));
    }


    private static boolean isEmpty(CharSequence s) {
        if (s == null) {
            return true;
        } else {
            return s.length() == 0;
        }
    }

    private static String encodeToString(byte[] src) {
        return src.length == 0 ? "" : new String(encode(src), DEFAULT_CHARSET);
    }

    private static byte[] encode(byte[] src) {
        return src.length == 0 ? src : Base64.getEncoder().encode(src);
    }
}
