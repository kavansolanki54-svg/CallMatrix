export interface TokenClaims {
  companyId?: number;
  roleId?: number;
  employeeId?: number;
  email?: string;
  sub?: string;
  [key: string]: any;
}

export function parseJwt(token: string): TokenClaims | null {
  try {
    const base64Url = token.split('.')[1];
    if (!base64Url) return null;
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch (error) {
    console.error('Failed to parse JWT token:', error);
    return null;
  }
}

export function getCompanyIdFromToken(): number | null {
  if (typeof window === 'undefined') return null;

  const token = localStorage.getItem('token');
  if (token) {
    const claims = parseJwt(token);
    if (claims) {
      const cid = claims.companyId || claims.CompanyId || claims.company_id || claims.tenant;
      if (cid !== undefined && cid !== null) {
        return Number(cid);
      }
    }
  }

  const userStr = localStorage.getItem('user');
  if (userStr) {
    try {
      const user = JSON.parse(userStr);
      if (user.companyId !== undefined && user.companyId !== null) {
        return Number(user.companyId);
      }
    } catch (e) {
      console.error('Error reading user session:', e);
    }
  }

  return null;
}

export function getUserIdFromToken(): number | null {
  debugger;
  if (typeof window === 'undefined') return null;

  const token = localStorage.getItem('token');
  if (token) {
    const claims = parseJwt(token);
    if (claims) {
      const nameIdentifierUri = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier";
      const uid = claims[nameIdentifierUri] ?? claims.nameid ?? claims.sub ?? claims.employeeId ?? claims.id ?? claims.userId ?? claims.UserId;
      if (uid !== undefined && uid !== null) {
        return Number(uid);
      }
    }
  }

  const userStr = localStorage.getItem('user');
  if (userStr) {
    try {
      const user = JSON.parse(userStr);
      const uid = user.id ?? user.userId ?? user.UserId ?? user.employeeId;
      if (uid !== undefined && uid !== null) {
        return Number(uid);
      }
    } catch (e) {
      console.error('Error reading user session:', e);
    }
  }

  return null;
}
