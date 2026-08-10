using System.Data;

namespace Callalyze.DAL.Connection
{
    public interface IDbConnectionFactory
    {
        IDbConnection CreateConnection();
    }
}
