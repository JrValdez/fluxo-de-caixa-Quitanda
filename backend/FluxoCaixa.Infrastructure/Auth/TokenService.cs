using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using FluxoCaixa.Application.Common.Interfaces;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace FluxoCaixa.Infrastructure.Auth;

/// <summary>Emite tokens JWT assinados com HMAC-SHA256.</summary>
public class TokenService : ITokenService
{
    private readonly JwtSettings _settings;

    public TokenService(IOptions<JwtSettings> settings) => _settings = settings.Value;

    public TokenResult GerarToken(Guid usuarioId, string email, string nomeCompleto, IEnumerable<string> perfis)
    {
        var expiraEm = DateTime.UtcNow.AddMinutes(_settings.ExpiracaoMinutos);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, usuarioId.ToString()),
            new(JwtRegisteredClaimNames.Email, email),
            new(ClaimTypes.NameIdentifier, usuarioId.ToString()),
            new(ClaimTypes.Name, nomeCompleto),
            new("nome", nomeCompleto),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };
        claims.AddRange(perfis.Select(p => new Claim(ClaimTypes.Role, p)));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_settings.Chave));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _settings.Emissor,
            audience: _settings.Audiencia,
            claims: claims,
            expires: expiraEm,
            signingCredentials: creds);

        var jwt = new JwtSecurityTokenHandler().WriteToken(token);
        return new TokenResult(jwt, expiraEm);
    }
}
