namespace Callalyze.DAL.Data;

public interface ICurrentUserService
{
    int? EmployeeId { get; }
    int? CompanyId { get; }
}
