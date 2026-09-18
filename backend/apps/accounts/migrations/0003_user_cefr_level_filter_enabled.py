from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0002_user_cefr_level'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='cefr_level_filter_enabled',
            field=models.BooleanField(default=False),
        ),
    ]
