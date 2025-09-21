import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/magento_native_service.dart';
import 'purchase_screen.dart';

/// Карточка продукта с информацией о покупке
class ProductCard extends StatelessWidget {
  final Season? season;
  final Episode? episode;
  final VoidCallback? onTap;
  final bool showPurchaseButton;

  const ProductCard({
    Key? key,
    this.season,
    this.episode,
    this.onTap,
    this.showPurchaseButton = true,
  })  : assert(season != null || episode != null,
            'Either season or episode must be provided'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = season ?? episode!;
    final isSeason = season != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(context, product),
            _buildContentSection(context, product, isSeason),
            if (showPurchaseButton)
              _buildPurchaseSection(context, product, isSeason),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, dynamic product) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.secondaryColor.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Фоновое изображение
          if (product.image.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                product.image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage(product);
                },
              ),
            )
          else
            _buildPlaceholderImage(product),

          // Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Статус покупки
          Positioned(
            top: 15,
            right: 15,
            child: _buildPurchaseStatus(product.isPurchased),
          ),

          // Play button для купленных эпизодов
          if (product.isPurchased && episode != null)
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(dynamic product) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          product is Season ? Icons.playlist_play : Icons.play_arrow,
          size: 50,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildPurchaseStatus(bool isPurchased) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPurchased ? Colors.green : AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPurchased ? Icons.check_circle : Icons.shopping_cart,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isPurchased ? 'Куплено' : 'Купить',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(
      BuildContext context, dynamic product, bool isSeason) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Описание
          Text(
            product.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Дополнительная информация
          Row(
            children: [
              Icon(
                isSeason ? Icons.playlist_play : Icons.play_arrow,
                size: 16,
                color: Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                isSeason ? 'Сезон' : 'Эпизод',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              if (product.price > 0)
                Text(
                  '${product.price.toStringAsFixed(2)} ${product.currency}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),

          // Информация об эпизодах для сезона
          if (isSeason && season != null && season!.episodes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${season!.episodes.length} эпизодов',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPurchaseSection(
      BuildContext context, dynamic product, bool isSeason) {
    if (product.isPurchased) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Доступно для воспроизведения',
                style: TextStyle(
                  color: Colors.green[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Навигация к воспроизведению
                if (onTap != null) onTap!();
              },
              child: const Text(
                'Смотреть',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showPurchaseDialog(context, product, isSeason),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Купить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => _showProductDetails(context, product, isSeason),
            icon: const Icon(Icons.info_outline),
            label: const Text('Подробнее'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(
      BuildContext context, dynamic product, bool isSeason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'Купить ${isSeason ? 'сезон' : 'эпизод'}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Цена: ${product.price.toStringAsFixed(2)} ${product.currency}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPurchase(context, product, isSeason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Купить'),
          ),
        ],
      ),
    );
  }

  void _navigateToPurchase(
      BuildContext context, dynamic product, bool isSeason) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseScreen(
          productId: product.id,
          productType: isSeason ? 'season' : 'episode',
          productName: product.name,
          productDescription: product.description,
          productImage: product.image,
          price: product.price,
          currency: product.currency,
          isPurchased: product.isPurchased,
        ),
      ),
    );
  }

  void _showProductDetails(
      BuildContext context, dynamic product, bool isSeason) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Заголовок
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Описание
            Text(
              product.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            // Цена
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Цена:',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${product.price.toStringAsFixed(2)} ${product.currency}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Информация об эпизодах для сезона
            if (isSeason && season != null && season!.episodes.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Эпизоды (${season!.episodes.length}):',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ...season!.episodes.take(5).map((episode) => ListTile(
                    leading: const Icon(Icons.play_arrow, color: Colors.white),
                    title: Text(
                      episode.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: episode.isPurchased
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : Text(
                            '${episode.price.toStringAsFixed(2)} ${episode.currency}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  )),
              if (season!.episodes.length > 5)
                Text(
                  '... и еще ${season!.episodes.length - 5} эпизодов',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],

            const SizedBox(height: 20),

            // Кнопка покупки
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToPurchase(context, product, isSeason);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Купить сейчас',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
