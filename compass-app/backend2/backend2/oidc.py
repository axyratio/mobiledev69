def userinfo(claims, user):
    claims['name'] = f'{user.first_name} {user.last_name}'.strip()
    claims['given_name'] = user.first_name
    claims['family_name'] = user.last_name
    claims['email'] = user.email
    claims['preferred_username'] = user.username
    return claims