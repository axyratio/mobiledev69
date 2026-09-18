from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0003_user_cefr_level_filter_enabled'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='highlight_filter_by_level_enabled',
            field=models.BooleanField(default=True),
        ),
    ]
