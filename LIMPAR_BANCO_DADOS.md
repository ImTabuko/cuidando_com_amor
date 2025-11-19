# Como Limpar o Banco de Dados

Este guia explica como limpar os dados do banco de dados MongoDB.

## ⚠️ ATENÇÃO
**Essas operações são IRREVERSÍVEIS!** Todos os dados serão permanentemente deletados.

## Opções Disponíveis

### 1. Limpar TUDO (usuários, matches, chats, mensagens)

**URL:** `DELETE https://cuidando-com-amor-ssud.vercel.app/api/admin/clear-all?key=admin123`

**Exemplo usando curl:**
```bash
curl -X DELETE "https://cuidando-com-amor-ssud.vercel.app/api/admin/clear-all?key=admin123"
```

**Exemplo usando navegador:**
Abra esta URL no navegador:
```
https://cuidando-com-amor-ssud.vercel.app/api/admin/clear-all?key=admin123
```

### 2. Limpar apenas Usuários

**URL:** `DELETE https://cuidando-com-amor-ssud.vercel.app/api/admin/clear-users?key=admin123`

### 3. Limpar apenas Matches

**URL:** `DELETE https://cuidando-com-amor-ssud.vercel.app/api/admin/clear-matches?key=admin123`

### 4. Limpar apenas Chats e Mensagens

**URL:** `DELETE https://cuidando-com-amor-ssud.vercel.app/api/admin/clear-chats?key=admin123`

## Segurança

Por padrão, a chave de acesso é `admin123`. Para maior segurança em produção:

1. Defina uma variável de ambiente `ADMIN_KEY` no Vercel/Render
2. Use uma chave forte e secreta
3. Não compartilhe a chave publicamente

## Resposta de Sucesso

```json
{
  "success": true,
  "message": "Banco de dados limpo com sucesso",
  "deleted": {
    "users": 10,
    "matches": 5,
    "chats": 3,
    "messages": 50
  }
}
```

## Resposta de Erro

Se a chave estiver incorreta:
```json
{
  "error": "Acesso negado. Chave inválida."
}
```


