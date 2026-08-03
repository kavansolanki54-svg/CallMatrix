using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class EnumMaster
{
    public int EnumId { get; set; }

    public short EnumCategoryId { get; set; }

    public string EnumName { get; set; } = null!;

    public int SortOrder { get; set; }

    public bool IsActive { get; set; }

    public virtual EnumCategory EnumCategory { get; set; } = null!;

    public virtual ICollection<RoleMaster> RoleMasters { get; set; } = new List<RoleMaster>();
}
