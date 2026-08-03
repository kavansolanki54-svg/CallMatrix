class UserModel {
  final int employeeId;
  final String userName;
  final String email;
  final String? profilePhoto;
  final String? phone;

  UserModel({
    required this.employeeId,
    required this.userName,
    required this.email,
    this.profilePhoto,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      employeeId: json['employeeID'] ?? json['employeeId'] ?? 0,
      userName: json['userName'] ?? json['employeeName'] ?? '',
      email: json['email'] ?? '',
      profilePhoto: json['profilePhoto'],
      phone: json['mobileNo'] ?? json['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
    'employeeID': employeeId,
    'userName': userName,
    'email': email,
    'profilePhoto': profilePhoto,
    'mobileNo': phone,
  };
}
