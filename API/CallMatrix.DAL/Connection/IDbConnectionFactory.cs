using System.Data;

namespace CallMatrix.DAL.Connection
{
    public interface IDbConnectionFactory
    {
        IDbConnection CreateConnection();
    }
}
