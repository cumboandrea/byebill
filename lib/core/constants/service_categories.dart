/// Categorías genéricas para servicios sin logo propio (gimnasio, cine, etc.).
/// Al seleccionar una categoría en el formulario, el campo "Servicio" se
/// autocompleta con su [name] y se guarda el [iconPath] en la suscripción.
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.iconPath,
  });

  final String id;
  final String name;
  final String iconPath;
}

const List<ServiceCategory> serviceCategories = [
  ServiceCategory(
    id: 'category_gym',
    name: 'Gimnasio',
    iconPath: 'assets/logos/category_gym.svg',
  ),
  ServiceCategory(
    id: 'category_cinema',
    name: 'Cine',
    iconPath: 'assets/logos/category_cinema.svg',
  ),
  ServiceCategory(
    id: 'category_hosting',
    name: 'Hosting',
    iconPath: 'assets/logos/category_hosting.svg',
  ),
  ServiceCategory(
    id: 'category_seguridad',
    name: 'Seguridad',
    iconPath: 'assets/logos/category_vpn.svg',
  ),
  ServiceCategory(
    id: 'category_finance',
    name: 'Finanzas',
    iconPath: 'assets/logos/category_finance.svg',
  ),
  ServiceCategory(
    id: 'category_travel',
    name: 'Viajes',
    iconPath: 'assets/logos/category_travel.svg',
  ),
  ServiceCategory(
    id: 'category_games',
    name: 'Videojuegos',
    iconPath: 'assets/logos/category_games.svg',
  ),
  ServiceCategory(
    id: 'category_news',
    name: 'Noticias',
    iconPath: 'assets/logos/category_news.svg',
  ),
  ServiceCategory(
    id: 'category_delivery',
    name: 'Delivery',
    iconPath: 'assets/logos/category_delivery.svg',
  ),
  ServiceCategory(
    id: 'category_ai',
    name: 'AI',
    iconPath: 'assets/logos/category_ai.svg',
  ),
  ServiceCategory(
    id: 'category_general',
    name: 'General',
    iconPath: 'assets/logos/category_general.svg',
  ),
];