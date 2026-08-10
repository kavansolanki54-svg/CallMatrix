using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Callalyze.DAL.Entities;

[Table("ApiKeys")]
public class ApiKeySetting
{
    [Key]
    public int Id { get; set; }

    [Required]
    [StringLength(100)]
    public string ServiceName { get; set; } = null!;

    [Required]
    [StringLength(500)]
    [Column("ApiKey")]
    public string Key { get; set; } = null!;

    [StringLength(500)]
    public string? ApiSecret { get; set; }

    [Required]
    [StringLength(20)]
    public string Environment { get; set; } = "Production";

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.Now;

    public DateTime? UpdatedAt { get; set; }
}
