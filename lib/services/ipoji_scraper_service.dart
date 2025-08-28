import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class IpojiScraperService {
  static const Duration timeoutDuration = Duration(seconds: 30);

  /// Scrapes company details and document links from IPOji URL
  static Future<Map<String, dynamic>> scrapeIpojiData(String url) async {
    try {
      // Validate URL
      if (!url.contains('ipoji.com/ipo/')) {
        throw Exception(
            'Invalid IPOji URL. Please provide a valid IPOji IPO URL.');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode != 200) {
        throw Exception('Failed to load page: ${response.statusCode}');
      }

      final document = html_parser.parse(response.body);

      return {
        'company_details': _extractCompanyDetails(document),
        'document_links': _extractDocumentLinks(document),
        'company_logo': _extractCompanyLogo(document),
        'expected_premium': _extractExpectedPremium(document),
      };
    } catch (e) {
      throw Exception('Error scraping IPOji data: $e');
    }
  }

  /// Extract company details from the HTML document
  static Map<String, String?> _extractCompanyDetails(Document document) {
    final companyDetails = <String, String?>{};

    try {
      // Extract company contact details from the "Company Contact Details" section
      final companyContactCards = document.querySelectorAll('.otherCard .card');
      for (final card in companyContactCards) {
        final cardHeader = card.querySelector('.card-header span');
        if (cardHeader != null &&
            cardHeader.text.contains('Company Contact Details')) {
          final cardBody = card.querySelector('.card-body');
          if (cardBody != null) {
            // Extract company name from orgName
            final orgNameElement = cardBody.querySelector('.orgName');
            if (orgNameElement != null) {
              companyDetails['company_name'] = orgNameElement.text.trim();
            }

            // Extract address
            final addressElement = cardBody.querySelector('address');
            if (addressElement != null) {
              companyDetails['address'] = addressElement.text.trim();
            }

            // Extract phone, email, and website from the basics section
            final basicsSection = cardBody.querySelector('.basics');
            if (basicsSection != null) {
              final paragraphs = basicsSection.querySelectorAll('p');
              for (final p in paragraphs) {
                final text = p.text.toLowerCase();
                if (text.contains('phone:')) {
                  final phoneSpan = p.querySelector('span[aria-label="value"]');
                  if (phoneSpan != null) {
                    companyDetails['phone'] = phoneSpan.text.trim();
                  }
                } else if (text.contains('email:')) {
                  // Try multiple approaches to get email
                  final emailSpan = p.querySelector('span[aria-label="value"]');
                  if (emailSpan != null) {
                    companyDetails['email'] = emailSpan.text.trim();
                  } else {
                    // Fallback: extract email directly from text after "Email:"
                    final emailText = p.text;
                    final emailIndex =
                        emailText.toLowerCase().indexOf('email:');
                    if (emailIndex != -1) {
                      final afterEmail =
                          emailText.substring(emailIndex + 6).trim();
                      final emailMatch = RegExp(r'[\w\.-]+@[\w\.-]+\.\w+')
                          .firstMatch(afterEmail);
                      if (emailMatch != null) {
                        companyDetails['email'] = emailMatch.group(0);
                      }
                    }
                  }
                } else if (text.contains('website:')) {
                  final websiteLink = p.querySelector('a[aria-label="value"]');
                  if (websiteLink != null) {
                    companyDetails['website'] = websiteLink.attributes['href'];
                  }
                }
              }
            }
          }
          break; // Found the company contact details card, no need to continue
        }
      }
    } catch (e) {
      print('Error extracting company details: $e');
    }

    return companyDetails;
  }

  /// Extract document links (DRHP, RHP, Anchor) from the HTML document
  static Map<String, String?> _extractDocumentLinks(Document document) {
    final documentLinks = <String, String?>{};

    try {
      // Look for IPO Docs section in the listing details
      final ipoDocsElements =
          document.querySelectorAll('[data-role="IPO_Docs"]');
      for (final docsElement in ipoDocsElements) {
        final links = docsElement.querySelectorAll('a[href]');
        for (final link in links) {
          final href = link.attributes['href'];
          final text = link.text.toLowerCase().trim();

          if (href != null) {
            if (text.contains('drhp')) {
              documentLinks['drhp'] = href;
            } else if (text.contains('rhp')) {
              documentLinks['rhp'] = href;
            } else if (text.contains('anchor')) {
              documentLinks['anchor'] = href;
            }
          }
        }
      }

      // Fallback: Look for document links in various possible locations
      if (documentLinks.isEmpty) {
        final linkElements = document.querySelectorAll(
            'a[href*=".pdf"], a[href*="document"], a[href*="drhp"], a[href*="rhp"], a[href*="anchor"]');

        for (final link in linkElements) {
          final href = link.attributes['href'];
          final text = link.text.toLowerCase();

          if (href != null) {
            if (text.contains('drhp') || href.toLowerCase().contains('drhp')) {
              documentLinks['drhp'] ??= href;
            } else if (text.contains('rhp') ||
                href.toLowerCase().contains('rhp')) {
              documentLinks['rhp'] ??= href;
            } else if (text.contains('anchor') ||
                href.toLowerCase().contains('anchor')) {
              documentLinks['anchor'] ??= href;
            }
          }
        }
      }
    } catch (e) {
      print('Error extracting document links: $e');
    }

    return documentLinks;
  }

  /// Extract company logo URL from the HTML document
  static String? _extractCompanyLogo(Document document) {
    try {
      // Look for company logo in the IPO cover section
      final logoElement = document.querySelector('.ipo_cover img');
      if (logoElement != null) {
        final src = logoElement.attributes['src'];
        if (src != null) {
          return src; // IPOji URLs are already absolute
        }
      }

      // Fallback: Look for company logo in various possible selectors
      final logoSelectors = [
        '.company-logo img',
        '.logo img',
        'img[alt*="logo"]',
        'img[class*="logo"]',
        '.ipo-header img',
        '.company-info img'
      ];

      for (final selector in logoSelectors) {
        final element = document.querySelector(selector);
        if (element != null) {
          final src = element.attributes['src'];
          if (src != null) {
            return _normalizeUrl(src);
          }
        }
      }
    } catch (e) {
      print('Error extracting company logo: $e');
    }
    return null;
  }

  /// Extract expected premium from the HTML document
  static String? _extractExpectedPremium(Document document) {
    try {
      // Look for expected premium in the top card section
      final premiumElement =
          document.querySelector('[data-role="expire_premium"]');
      if (premiumElement != null) {
        final text = premiumElement.text.trim();
        if (text.isNotEmpty) {
          return text;
        }
      }

      // Fallback: Look for premium information in various possible locations
      final premiumSelectors = [
        '[class*="premium"]',
        '[data-label*="premium"]',
        '.expected-premium',
        '.premium-value'
      ];

      for (final selector in premiumSelectors) {
        final element = document.querySelector(selector);
        if (element != null) {
          final text = element.text.trim();
          if (text.isNotEmpty && (text.contains('%') || text.contains('₹'))) {
            return text;
          }
        }
      }

      // Alternative method: look in table rows or definition lists
      final rows = document.querySelectorAll('tr, dt, .info-row');
      for (final row in rows) {
        final text = row.text.toLowerCase();
        if (text.contains('premium') || text.contains('expected')) {
          final nextElement = row.nextElementSibling;
          if (nextElement != null) {
            final premiumText = nextElement.text.trim();
            if (premiumText.isNotEmpty &&
                (premiumText.contains('%') || premiumText.contains('₹'))) {
              return premiumText;
            }
          }
        }
      }
    } catch (e) {
      print('Error extracting expected premium: $e');
    }
    return null;
  }

  /// Normalize URL to ensure it's absolute
  static String _normalizeUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    } else if (url.startsWith('//')) {
      return 'https:$url';
    } else if (url.startsWith('/')) {
      return 'https://www.ipoji.com$url';
    } else {
      return 'https://www.ipoji.com/$url';
    }
  }
}
