using System.Security.Cryptography;
using System.Text;

namespace CallMatrix.Utilities.Helper
{
    public class Encryption
    {
        private string EncryptionKey { get; set; } = "espr";

        public string HashPassword(string email, string password)
        {
            // Use PBKDF2 to hash password securely
            byte[] salt = new byte[16];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(salt);
            }

            byte[] hash;
            using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 100000, HashAlgorithmName.SHA256))
            {
                hash = pbkdf2.GetBytes(32);
            }

            byte[] hashBytes = new byte[48];
            Array.Copy(salt, 0, hashBytes, 0, 16);
            Array.Copy(hash, 0, hashBytes, 16, 32);

            return "AQAAAA" + Convert.ToBase64String(hashBytes); // Prefix matches ASP.NET Identity format structure
        }

        public bool VerifyPassword(string email, string hashedPassword, string providedPassword)
        {
            if (string.IsNullOrEmpty(hashedPassword) || !hashedPassword.StartsWith("AQAAAA"))
            {
                return false;
            }

            try
            {
                string base64Part = hashedPassword.Substring(6);
                byte[] hashBytes = Convert.FromBase64String(base64Part);

                byte[] salt = new byte[16];
                Array.Copy(hashBytes, 0, salt, 0, 16);

                byte[] expectedHash = new byte[32];
                Array.Copy(hashBytes, 16, expectedHash, 0, 32);

                byte[] actualHash;
                using (var pbkdf2 = new Rfc2898DeriveBytes(providedPassword, salt, 100000, HashAlgorithmName.SHA256))
                {
                    actualHash = pbkdf2.GetBytes(32);
                }

                return CryptographicOperations.FixedTimeEquals(expectedHash, actualHash);
            }
            catch
            {
                return false;
            }
        }


        public string Encrypt(string clearText)
        {
            //string EncryptionKey = "abc123";

            byte[] clearBytes = Encoding.Unicode.GetBytes(clearText);
            using (Aes encryptor = Aes.Create())
            {
                Rfc2898DeriveBytes pdb = new Rfc2898DeriveBytes(EncryptionKey, new byte[] { 0x49, 0x76, 0x61, 0x6e, 0x20, 0x4d, 0x65, 0x64, 0x76, 0x65, 0x64, 0x65, 0x76 });
                encryptor.Key = pdb.GetBytes(32);
                encryptor.IV = pdb.GetBytes(16);
                using (MemoryStream ms = new MemoryStream())
                {
                    using (CryptoStream cs = new CryptoStream(ms, encryptor.CreateEncryptor(), CryptoStreamMode.Write))
                    {
                        cs.Write(clearBytes, 0, clearBytes.Length);
                        cs.Close();
                    }
                    clearText = Convert.ToBase64String(ms.ToArray());
                }
            }
            return clearText;
        }

        public string Decrypt(string cipherText)
        {
            //string EncryptionKey = "abc123";
            if (string.IsNullOrEmpty(cipherText))
            {
                return "";
            }
            ;
            string EncryptionKey = "espr";
            cipherText = cipherText.Replace(" ", "+");
            byte[] cipherBytes = Convert.FromBase64String(cipherText);
            using (Aes encryptor = Aes.Create())
            {
                Rfc2898DeriveBytes pdb = new Rfc2898DeriveBytes(EncryptionKey, new byte[] { 0x49, 0x76, 0x61, 0x6e, 0x20, 0x4d, 0x65, 0x64, 0x76, 0x65, 0x64, 0x65, 0x76 });
                encryptor.Key = pdb.GetBytes(32);
                encryptor.IV = pdb.GetBytes(16);
                using (MemoryStream ms = new MemoryStream())
                {
                    using (CryptoStream cs = new CryptoStream(ms, encryptor.CreateDecryptor(), CryptoStreamMode.Write))
                    {
                        cs.Write(cipherBytes, 0, cipherBytes.Length);
                        cs.Close();
                    }
                    cipherText = Encoding.Unicode.GetString(ms.ToArray());
                }
            }
            return cipherText;
        }

        #region Parameter value
        public string EncryptParameter(string value)
        {
            try
            {
                byte[] Key = new byte[] { 241, 22, 224, 30, 167, 180, 187, 197, 233, 249, 34, 128, 161, 237, 228, 109, 85, 82, 107, 31, 244, 6, 101, 112 };
                byte[] IV = new byte[] { 165, 254, 18, 14, 219, 220, 17, 122 };

                // Check arguments.
                if (value == null || value.Length <= 0)
                    throw new ArgumentNullException("plainText");
                if (Key == null || Key.Length <= 0)
                    throw new ArgumentNullException("Key");
                if (IV == null || IV.Length <= 0)
                    throw new ArgumentNullException("Key");
                byte[] encrypted;
                // Create an TripleDESCryptoServiceProvider object
                // with the specified key and IV.
                using (TripleDESCryptoServiceProvider tdsAlg = new TripleDESCryptoServiceProvider())
                {
                    tdsAlg.Key = Key;
                    tdsAlg.IV = IV;

                    // Create a decrytor to perform the stream transform.
                    ICryptoTransform encryptor = tdsAlg.CreateEncryptor(tdsAlg.Key, tdsAlg.IV);

                    // Create the streams used for encryption.
                    using (MemoryStream msEncrypt = new MemoryStream())
                    {
                        using (CryptoStream csEncrypt = new CryptoStream(msEncrypt, encryptor, CryptoStreamMode.Write))
                        {
                            using (StreamWriter swEncrypt = new StreamWriter(csEncrypt))
                            {
                                //Write all data to the stream.
                                swEncrypt.Write(value);
                            }
                            encrypted = msEncrypt.ToArray();
                        }
                    }
                }
                // Return the encrypted bytes from the memory stream.
                return BitConverter.ToString(encrypted);
            }
            catch
            {
                return "0";
            }
        }

        public string DecryptParameter(string values)
        {
            try
            {
                byte[] Key = new byte[] { 241, 22, 224, 30, 167, 180, 187, 197, 233, 249, 34, 128, 161, 237, 228, 109, 85, 82, 107, 31, 244, 6, 101, 112 };
                byte[] IV = new byte[] { 165, 254, 18, 14, 219, 220, 17, 122 };

                //return BitConverter.ToString(values); 
                byte[] value = values.Split('-').Select(x => byte.Parse(x, System.Globalization.NumberStyles.HexNumber)).ToArray();

                // Check arguments.
                if (value == null || value.Length <= 0)
                    throw new ArgumentNullException("cipherText");
                if (Key == null || Key.Length <= 0)
                    throw new ArgumentNullException("Key");
                if (IV == null || IV.Length <= 0)
                    throw new ArgumentNullException("Key");

                // Declare the string used to hold
                // the decrypted text.
                string plaintext = null;

                // Create an TripleDESCryptoServiceProvider object
                // with the specified key and IV.
                using (TripleDESCryptoServiceProvider tdsAlg = new TripleDESCryptoServiceProvider())
                {
                    tdsAlg.Key = Key;
                    tdsAlg.IV = IV;

                    // Create a decrytor to perform the stream transform.
                    ICryptoTransform decryptor = tdsAlg.CreateDecryptor(tdsAlg.Key, tdsAlg.IV);

                    // Create the streams used for decryption.
                    using (MemoryStream msDecrypt = new MemoryStream(value))
                    {
                        using (CryptoStream csDecrypt = new CryptoStream(msDecrypt, decryptor, CryptoStreamMode.Read))
                        {
                            using (StreamReader srDecrypt = new StreamReader(csDecrypt))
                            {

                                // Read the decrypted bytes from the decrypting stream
                                // and place them in a string.
                                plaintext = srDecrypt.ReadToEnd();
                            }
                        }
                    }
                }
                return plaintext;
            }
            catch
            {
                return "0";
            }
        }
        #endregion
    }//class
}
