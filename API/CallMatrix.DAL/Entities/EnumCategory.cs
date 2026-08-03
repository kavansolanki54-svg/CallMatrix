using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class EnumCategory
{
    public short EnumCategoryId { get; set; }

    public string CategoryName { get; set; } = null!;

    public bool IsActive { get; set; }

    public virtual ICollection<EnumMaster> EnumMasters { get; set; } = new List<EnumMaster>();
}
