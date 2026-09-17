import django.db.models.deletion
import django.utils.timezone
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('stories', '0001_initial'),
    ]

    operations = [
        migrations.RenameField(
            model_name='word',
            old_name='word',
            new_name='lemma',
        ),
        migrations.AlterField(
            model_name='word',
            name='lemma',
            field=models.CharField(max_length=128),
        ),
        migrations.AlterField(
            model_name='word',
            name='source',
            field=models.CharField(default='oxford3000', max_length=32),
        ),
        migrations.AddField(
            model_name='word',
            name='word_type',
            field=models.CharField(
                choices=[('single', 'Single'), ('phrase', 'Phrase')],
                default='single',
                max_length=10,
            ),
        ),
        migrations.AddField(
            model_name='word',
            name='pos',
            field=models.CharField(
                choices=[
                    ('noun', 'Noun'),
                    ('verb', 'Verb'),
                    ('adj', 'Adjective'),
                    ('adv', 'Adverb'),
                    ('prep', 'Preposition'),
                    ('conj', 'Conjunction'),
                    ('pron', 'Pronoun'),
                    ('det', 'Determiner'),
                    ('number', 'Number'),
                    ('exclam', 'Exclamation'),
                    ('other', 'Other'),
                ],
                default='noun',
                max_length=10,
            ),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='word',
            name='cefr_level',
            field=models.CharField(
                choices=[('A1', 'A1'), ('A2', 'A2'), ('B1', 'B1'), ('B2', 'B2')],
                default='A1',
                max_length=2,
            ),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='word',
            name='definition_en',
            field=models.TextField(blank=True, default=''),
        ),
        migrations.AddField(
            model_name='word',
            name='definition_th',
            field=models.TextField(blank=True, default=''),
        ),
        migrations.AddField(
            model_name='word',
            name='example',
            field=models.TextField(blank=True, default=''),
        ),
        migrations.AddField(
            model_name='word',
            name='is_active',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='word',
            name='created_at',
            field=models.DateTimeField(auto_now_add=True, default=django.utils.timezone.now),
            preserve_default=False,
        ),
        migrations.AlterModelOptions(
            name='word',
            options={'ordering': ['lemma']},
        ),
        migrations.AddConstraint(
            model_name='word',
            constraint=models.UniqueConstraint(fields=('lemma', 'pos'), name='unique_word_lemma_pos'),
        ),
        migrations.AddIndex(
            model_name='word',
            index=models.Index(fields=['cefr_level', 'is_active'], name='stories_wor_cefr_le_c69109_idx'),
        ),
        migrations.CreateModel(
            name='WordForm',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('form', models.CharField(max_length=128)),
                (
                    'form_type',
                    models.CharField(
                        choices=[
                            ('base', 'Base'),
                            ('plural', 'Plural'),
                            ('past', 'Past'),
                            ('past_participle', 'Past participle'),
                            ('gerund', 'Gerund'),
                            ('third_person', 'Third person'),
                            ('comparative', 'Comparative'),
                            ('superlative', 'Superlative'),
                        ],
                        max_length=20,
                    ),
                ),
                ('word', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='forms', to='stories.word')),
            ],
        ),
        migrations.AddIndex(
            model_name='wordform',
            index=models.Index(fields=['form'], name='stories_wor_form_269b16_idx'),
        ),
        migrations.AddConstraint(
            model_name='wordform',
            constraint=models.UniqueConstraint(fields=('word', 'form'), name='unique_word_form'),
        ),
    ]
