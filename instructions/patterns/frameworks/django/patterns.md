# Djangoパターン

## MVTアーキテクチャ

### Model-View-Template構造
Djangoコンポーネントを適切に整理。

```python
# models.py - データレイヤー
from django.db import models
from django.contrib.auth import get_user_model

class Article(models.Model):
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    author = models.ForeignKey(get_user_model(), on_delete=models.CASCADE)
    content = models.TextField()
    published_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-published_at']
        indexes = [
            models.Index(fields=['slug']),
            models.Index(fields=['-published_at']),
        ]
    
    def __str__(self):
        return self.title

# views.py - ビジネスロジック
from django.shortcuts import get_object_or_404
from django.views.generic import ListView, DetailView

class ArticleListView(ListView):
    model = Article
    template_name = 'articles/list.html'
    context_object_name = 'articles'
    paginate_by = 10
    
    def get_queryset(self):
        return Article.objects.select_related('author').prefetch_related('tags')

# urls.py - URLルーティング
from django.urls import path

app_name = 'articles'
urlpatterns = [
    path('', ArticleListView.as_view(), name='list'),
    path('<slug:slug>/', ArticleDetailView.as_view(), name='detail'),
]
```

## クエリ最適化

### Select RelatedとPrefetch Related
データベースクエリを最小化。

```python
# 良い例 - N+1クエリを回避
articles = Article.objects.select_related('author').prefetch_related('comments')

# 特定フィールドのみ取得
articles = Article.objects.only('title', 'slug', 'published_at')

# 重いフィールドを除外
articles = Article.objects.defer('content')

# 集計でアノテート
from django.db.models import Count, Avg
articles = Article.objects.annotate(
    comment_count=Count('comments'),
    avg_rating=Avg('ratings__score')
)

# 悪い例 - N+1クエリ問題
articles = Article.objects.all()
for article in articles:
    print(article.author.name)  # 毎回DBにアクセス
```

## カスタムマネージャーとQuerySet

### ビジネスロジックのカプセル化
クエリロジックをモデルに保持。

```python
# 良い例
class PublishedManager(models.Manager):
    def get_queryset(self):
        return super().get_queryset().filter(status='published')

class ArticleQuerySet(models.QuerySet):
    def published(self):
        return self.filter(status='published')
    
    def by_author(self, author):
        return self.filter(author=author)
    
    def recent(self, days=7):
        from django.utils import timezone
        from datetime import timedelta
        return self.filter(
            published_at__gte=timezone.now() - timedelta(days=days)
        )

class Article(models.Model):
    objects = ArticleQuerySet.as_manager()
    published = PublishedManager()
    
    # 使用例
    recent_articles = Article.objects.published().recent(30)
```

## フォーム処理

### ModelFormとバリデーション
フォームデータを適切に処理。

```python
# forms.py
from django import forms
from django.core.exceptions import ValidationError

class ArticleForm(forms.ModelForm):
    class Meta:
        model = Article
        fields = ['title', 'content', 'tags']
        widgets = {
            'content': forms.Textarea(attrs={'rows': 10}),
        }
    
    def clean_title(self):
        title = self.cleaned_data['title']
        if Article.objects.filter(title__iexact=title).exists():
            raise ValidationError('このタイトルの記事は既に存在します')
        return title
    
    def save(self, commit=True):
        article = super().save(commit=False)
        article.slug = slugify(article.title)
        if commit:
            article.save()
            self.save_m2m()
        return article

# views.py
from django.contrib import messages

class ArticleCreateView(LoginRequiredMixin, CreateView):
    model = Article
    form_class = ArticleForm
    
    def form_valid(self, form):
        form.instance.author = self.request.user
        messages.success(self.request, '記事が正常に作成されました')
        return super().form_valid(form)
```

## 認証と権限

### カスタムユーザーモデルと権限
適切なアクセス制御を実装。

```python
# models.py
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    bio = models.TextField(blank=True)
    avatar = models.ImageField(upload_to='avatars/', blank=True)
    
    def can_edit_article(self, article):
        return self == article.author or self.is_staff

# views.py
from django.contrib.auth.mixins import UserPassesTestMixin

class ArticleUpdateView(UserPassesTestMixin, UpdateView):
    model = Article
    
    def test_func(self):
        article = self.get_object()
        return self.request.user.can_edit_article(article)

# カスタム権限
from django.contrib.auth.decorators import user_passes_test

def is_author(user):
    return user.groups.filter(name='Authors').exists()

@user_passes_test(is_author)
def create_article(request):
    # ビューロジック
```

## ミドルウェア

### カスタムミドルウェア
リクエストをグローバルに処理。

```python
# 良い例
class RequestLoggingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # ビュー前
        request.request_id = str(uuid.uuid4())
        
        response = self.get_response(request)
        
        # ビュー後
        logger.info(f'リクエスト {request.request_id} がステータス {response.status_code} で完了')
        
        return response
    
    def process_exception(self, request, exception):
        logger.error(f'リクエスト {request.request_id} が失敗: {exception}')
        return None
```

## キャッシング

### キャッシュ戦略
キャッシングでパフォーマンスを最適化。

```python
# 良い例 - 複数のキャッシュ戦略
from django.core.cache import cache
from django.views.decorators.cache import cache_page
from django.core.cache.utils import make_template_fragment_key

# ビューキャッシング
@cache_page(60 * 15)  # 15分間キャッシュ
def article_list(request):
    # ビューロジック

# 低レベルキャッシング
def get_popular_articles():
    key = 'popular_articles'
    articles = cache.get(key)
    
    if articles is None:
        articles = Article.objects.annotate(
            view_count=Count('views')
        ).order_by('-view_count')[:10]
        cache.set(key, articles, 60 * 30)  # 30分
    
    return articles

# テンプレートフラグメントキャッシング
{% load cache %}
{% cache 500 article_list request.user.id %}
    <!-- 高コストなテンプレートレンダリング -->
{% endcache %}

# 保存時にキャッシュを無効化
def save(self, *args, **kwargs):
    super().save(*args, **kwargs)
    cache.delete('popular_articles')
```

## シグナル

### 疎結合イベント処理
モデルイベントに反応。

```python
# 良い例 - 疎結合ロジックにシグナルを使用
from django.db.models.signals import post_save, pre_delete
from django.dispatch import receiver

@receiver(post_save, sender=Article)
def create_article_slug(sender, instance, created, **kwargs):
    if created and not instance.slug:
        instance.slug = slugify(instance.title)
        instance.save()

@receiver(pre_delete, sender=Article)
def cleanup_article_files(sender, instance, **kwargs):
    # 関連ファイルをクリーンアップ
    if instance.featured_image:
        instance.featured_image.delete(save=False)

# カスタムシグナル
from django.dispatch import Signal

article_viewed = Signal()

# ビュー内
article_viewed.send(sender=Article, article=article, user=request.user)
```

## テスト

### 包括的なテストカバレッジ
モデル、ビュー、フォームをテスト。

```python
# 良い例
from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.urls import reverse

class ArticleModelTest(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='testuser',
            password='testpass'
        )
    
    def test_article_creation(self):
        article = Article.objects.create(
            title='テスト記事',
            author=self.user,
            content='テストコンテンツ'
        )
        self.assertEqual(str(article), 'テスト記事')
        self.assertTrue(article.slug)

class ArticleViewTest(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = get_user_model().objects.create_user(
            username='testuser',
            password='testpass'
        )
    
    def test_article_list_view(self):
        response = self.client.get(reverse('articles:list'))
        self.assertEqual(response.status_code, 200)
    
    def test_article_create_requires_login(self):
        response = self.client.get(reverse('articles:create'))
        self.assertEqual(response.status_code, 302)  # ログインへリダイレクト
```

## ベストプラクティスチェックリスト

- [ ] 最初からカスタムUserモデルを使用
- [ ] 適切なデータベースインデックスを実装
- [ ] select_relatedとprefetch_relatedを使用
- [ ] ビジネスロジック用のカスタムマネージャーを作成
- [ ] Djangoの組み込みセキュリティ機能を使用
- [ ] 適切なキャッシング戦略を実装
- [ ] 包括的なテストを記述
- [ ] 設定に環境変数を使用
- [ ] 静的ファイルを適切に処理
- [ ] 開発環境でDjango Debug Toolbarを使用
- [ ] 適切なロギングを実装
- [ ] データベーストランザクションを適切に使用