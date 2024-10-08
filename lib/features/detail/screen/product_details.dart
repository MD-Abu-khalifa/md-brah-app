import 'dart:async';

import 'package:active_ecommerce_flutter/app_config.dart';
import 'package:active_ecommerce_flutter/core/base_component_show.dart';
import 'package:active_ecommerce_flutter/core/failure/request_state.dart';
import 'package:active_ecommerce_flutter/core/my_extensions.dart';
import 'package:active_ecommerce_flutter/core/resources/assets_fonts.dart';
import 'package:active_ecommerce_flutter/core/services/service_locator.dart';
import 'package:active_ecommerce_flutter/custom/box_decorations.dart';
import 'package:active_ecommerce_flutter/custom/btn.dart';
import 'package:active_ecommerce_flutter/custom/device_info.dart';
import 'package:active_ecommerce_flutter/custom/lang_text.dart';
import 'package:active_ecommerce_flutter/custom/quantity_input.dart';
import 'package:active_ecommerce_flutter/custom/text_styles.dart';
import 'package:active_ecommerce_flutter/custom/toast_component.dart';
import 'package:active_ecommerce_flutter/data_model/product_details_response.dart';
import 'package:active_ecommerce_flutter/features/detail/widgets/bottom_button_nav.dart';
import 'package:active_ecommerce_flutter/features/detail/widgets/chat_seller.dart';
import 'package:active_ecommerce_flutter/features/detail/widgets/download_image.dart';
import 'package:active_ecommerce_flutter/features/detail/widgets/share_product_detail.dart';
import 'package:active_ecommerce_flutter/features/home/presentation/bloc/home_bloc.dart';
import 'package:active_ecommerce_flutter/helpers/color_helper.dart';
import 'package:active_ecommerce_flutter/helpers/main_helpers.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/helpers/system_config.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/presenter/cart_counter.dart';
import 'package:active_ecommerce_flutter/repositories/cart_repository.dart';
import 'package:active_ecommerce_flutter/repositories/chat_repository.dart';
import 'package:active_ecommerce_flutter/repositories/product_repository.dart';
import 'package:active_ecommerce_flutter/repositories/wishlist_repository.dart';
import 'package:active_ecommerce_flutter/screens/brand_products.dart';
import 'package:active_ecommerce_flutter/features/cart/presentation/view/pages/cart.dart';
import 'package:active_ecommerce_flutter/screens/chat.dart';
import 'package:active_ecommerce_flutter/screens/common_webview_screen.dart';
import 'package:active_ecommerce_flutter/features/auth/presentation/view/pages/login.dart';
import 'package:active_ecommerce_flutter/screens/product_reviews.dart';
import 'package:active_ecommerce_flutter/screens/seller_details.dart';
import 'package:active_ecommerce_flutter/screens/video_description_screen.dart';
import 'package:active_ecommerce_flutter/ui_elements/list_product_card.dart';
import 'package:active_ecommerce_flutter/ui_elements/mini_product_card.dart';
import 'package:badges/badges.dart' as badges;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:social_share/social_share.dart';
import 'package:toast/toast.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProductDetails extends StatefulWidget {
  int? id;

  ProductDetails({Key? key, this.id}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails>
    with TickerProviderStateMixin {
  bool _showCopied = false;
  String? _appbarPriceString = ". . .";
  int _currentImage = 0;
  ScrollController _mainScrollController =
      ScrollController(initialScrollOffset: 0.0);
  ScrollController _colorScrollController = ScrollController();
  ScrollController _variantScrollController = ScrollController();
  ScrollController _imageScrollController = ScrollController();
  TextEditingController sellerChatTitleController = TextEditingController();
  TextEditingController sellerChatMessageController = TextEditingController();

  double _scrollPosition = 0.0;

  Animation? _colorTween;
  late AnimationController _ColorAnimationController;
  WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..enableZoom(false);
  double webViewHeight = 50.0;

  CarouselController _carouselController = CarouselController();
  late BuildContext loadingcontext;

  //init values

  bool _isInWishList = false;
  var _productDetailsFetched = false;
  DetailedProduct? _productDetails;
  var _productImageList = [];
  var _colorList = [];
  int _selectedColorIndex = 0;
  var _selectedChoices = [];
  var _choiceString = "";
  String? _variant = "";
  String? _totalPrice = "...";
  var _singlePrice;
  var _singlePriceString;
  int? _quantity = 1;
  int? _stock = 0;
  var _stock_txt;

  double opacity = 0;

  List<dynamic> _relatedProducts = [];
  bool _relatedProductInit = false;
  List<dynamic> _topProducts = [];
  bool _topProductInit = false;

  @override
  void initState() {
    quantityText.text = "${_quantity ?? 0}";
    controller;
    _ColorAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 0));

    _colorTween = ColorTween(begin: Colors.transparent, end: Colors.white)
        .animate(_ColorAnimationController);

    _mainScrollController.addListener(() {
      _scrollPosition = _mainScrollController.position.pixels;

      if (_mainScrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (100 > _scrollPosition && _scrollPosition > 1) {
          opacity = _scrollPosition / 100;
        }
      }

      if (_mainScrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (100 > _scrollPosition && _scrollPosition > 1) {
          opacity = _scrollPosition / 100;

          if (100 > _scrollPosition) {
            opacity = 1;
          }
        }
      }
      print("opachity{} $_scrollPosition");

      setState(() {});
    });
    fetchAll();
    super.initState();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _variantScrollController.dispose();
    _imageScrollController.dispose();
    _colorScrollController.dispose();
    _ColorAnimationController.dispose();
    super.dispose();
  }

  fetchAll() {
    fetchProductDetails();
    if (is_logged_in.$ == true) {
      fetchWishListCheckInfo();
    }
    fetchRelatedProducts();
    fetchTopProducts();
  }

  // fetchVariantPrice() async {
  //   var response = await ProductRepository()
  //       .getVariantPrice(id: widget.id, quantity: _quantity);

  //   print(response);
  //   _totalPrice = response.data.price;
  //   setState(() {});
  // }

  fetchProductDetails() async {
    var productDetailsResponse =
        await ProductRepository().getProductDetails(id: widget.id);

    if (productDetailsResponse.detailed_products!.length > 0) {
      _productDetails = productDetailsResponse.detailed_products![0];
      sellerChatTitleController.text =
          productDetailsResponse.detailed_products![0].name!;
    }

    setProductDetailValues();

    setState(() {});
  }

  fetchRelatedProducts() async {
    var relatedProductResponse =
        await ProductRepository().getRelatedProducts(id: widget.id);
    _relatedProducts.addAll(relatedProductResponse.products!);
    _relatedProductInit = true;

    setState(() {});
  }

  fetchTopProducts() async {
    var topProductResponse =
        await ProductRepository().getTopFromThisSellerProducts(id: widget.id);
    _topProducts.addAll(topProductResponse.products!);
    _topProductInit = true;
  }

  setProductDetailValues() {
    if (_productDetails != null) {
      controller.loadHtmlString(makeHtml(_productDetails!.description!));
      _appbarPriceString = _productDetails!.price_high_low;
      _singlePrice = _productDetails!.calculable_price;
      _singlePriceString = _productDetails!.main_price;
      // fetchVariantPrice();
      _stock = _productDetails!.current_stock;
      _productDetails!.photos!.forEach((photo) {
        _productImageList.add(photo.path);
      });

      _productDetails!.choice_options!.forEach((choiceOpiton) {
        _selectedChoices.add(choiceOpiton.options![0]);
      });
      _productDetails!.colors!.forEach((color) {
        _colorList.add(color);
      });

      setChoiceString();

      // if (_productDetails!.colors.length > 0 ||
      //     _productDetails!.choice_options.length > 0) {
      //   fetchAndSetVariantWiseInfo(change_appbar_string: true);
      // }
      fetchAndSetVariantWiseInfo(change_appbar_string: true);
      _productDetailsFetched = true;

      setState(() {});
    }
  }

  setChoiceString() {
    _choiceString = _selectedChoices.join(",").toString();
    print(_choiceString);
    setState(() {});
  }

  fetchWishListCheckInfo() async {
    var wishListCheckResponse =
        await WishListRepository().isProductInUserWishList(
      product_id: widget.id,
    );

    //print("p&u:" + widget.id.toString() + " | " + _user_id.toString());
    _isInWishList = wishListCheckResponse.is_in_wishlist;
    setState(() {});
  }

  addToWishList() async {
    var wishListCheckResponse =
        await WishListRepository().add(product_id: widget.id);

    //print("p&u:" + widget.id.toString() + " | " + _user_id.toString());
    _isInWishList = wishListCheckResponse.is_in_wishlist;
    setState(() {});
  }

  removeFromWishList() async {
    var wishListCheckResponse =
        await WishListRepository().remove(product_id: widget.id);

    //print("p&u:" + widget.id.toString() + " | " + _user_id.toString());
    _isInWishList = wishListCheckResponse.is_in_wishlist;
    setState(() {});
  }

  onWishTap() {
    if (is_logged_in.$ == false) {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.you_need_to_log_in,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      return;
    }

    if (_isInWishList) {
      _isInWishList = false;
      setState(() {});
      removeFromWishList();
    } else {
      _isInWishList = true;
      setState(() {});
      addToWishList();
    }
  }

  setQuantity(quantity) {
    quantityText.text = "${quantity ?? 0}";
  }

  fetchAndSetVariantWiseInfo({bool change_appbar_string = true}) async {
    var colorString = _colorList.length > 0
        ? _colorList[_selectedColorIndex].toString().replaceAll("#", "")
        : "";

    /*print("color string: "+color_string);
    return;*/

    var variantResponse = await ProductRepository().getVariantWiseInfo(
        id: widget.id,
        color: colorString,
        variants: _choiceString,
        qty: _quantity);
    print("single price ${variantResponse.variantData!.price}");
    /*print("vr"+variantResponse.toJson().toString());
    return;*/

    // _singlePrice = variantResponse.price;
    _stock = variantResponse.variantData!.stock;
    _stock_txt = variantResponse.variantData!.stockTxt;
    if (_quantity! > _stock!) {
      _quantity = _stock;
    }

    _variant = variantResponse.variantData!.variant;

    //fetchVariantPrice();
    // _singlePriceString = variantResponse.price_string;
    _totalPrice = variantResponse.variantData!.price;

    // if (change_appbar_string) {
    //   _appbarPriceString = "${variantResponse.variant} ${_singlePriceString}";
    // }

    int pindex = 0;
    _productDetails!.photos?.forEach((photo) {
      //print('con:'+ (photo.variant == _variant && variantResponse.image != "").toString());
      if (photo.variant == _variant &&
          variantResponse.variantData!.image != "") {
        _currentImage = pindex;
        _carouselController.jumpToPage(pindex);
      }
      pindex++;
    });
    setQuantity(_quantity);
    setState(() {});
  }

  reset() {
    restProductDetailValues();
    _currentImage = 0;
    _productImageList.clear();
    _colorList.clear();
    _selectedChoices.clear();
    _relatedProducts.clear();
    _topProducts.clear();
    _choiceString = "";
    _variant = "";
    _selectedColorIndex = 0;
    _quantity = 1;
    _productDetailsFetched = false;
    _isInWishList = false;
    sellerChatTitleController.clear();
    setState(() {});
  }

  restProductDetailValues() {
    _appbarPriceString = " . . .";
    _productDetails = null;
    _productImageList.clear();
    _currentImage = 0;
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  // calculateTotalPrice() {
  //   print("sing $_singlePrice");
  //
  //   _totalPrice = (_singlePrice * _quantity).toStringAsFixed(2);
  //   setState(() {});
  // }

  _onVariantChange(_choice_options_index, value) {
    _selectedChoices[_choice_options_index] = value;
    setChoiceString();
    setState(() {});
    fetchAndSetVariantWiseInfo();
  }

  _onColorChange(index) {
    _selectedColorIndex = index;
    setState(() {});
    fetchAndSetVariantWiseInfo();
  }

  onPressAddToCart(context, snackbar) {
    addToCart(mode: "add_to_cart", context: context, snackbar: snackbar);
  }

  onPressBuyNow(context) {
    addToCart(mode: "buy_now", context: context);
  }

  addToCart({mode, context, snackbar}) async {
    if (is_logged_in.$ == false) {
      // ToastComponent.showDialog(AppLocalizations.of(context).common_login_warning, context,
      //     gravity: Toast.center, duration: Toast.lengthLong);
      Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
      return;
    }

    // print(widget.id);
    // print(_variant);
    // print(user_id.$);
    // print(_quantity);

    var cartAddResponse = await CartRepository()
        .getCartAddResponse(widget.id, _variant, user_id.$, _quantity);

    if (cartAddResponse.result == false) {
      ToastComponent.showDialog(cartAddResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong);
      return;
    } else {
      Provider.of<CartCounter>(context, listen: false).getCount();

      if (mode == "add_to_cart") {
        if (snackbar != null && context != null) {
          ScaffoldMessenger.of(context).showSnackBar(snackbar);
        }
        reset();
        fetchAll();
      } else if (mode == 'buy_now') {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return Cart(has_bottomnav: false);
        })).then((value) {
          onPopped(value);
        });
      }
    }
  }

  onPopped(value) async {
    reset();
    fetchAll();
  }

  onCopyTap(setState) {
    setState(() {
      _showCopied = true;
    });
    Timer timer = Timer(Duration(seconds: 3), () {
      setState(() {
        _showCopied = false;
      });
    });
  }

  onPressShare(BuildContext context) {
    context.showBottomSheet(
      child: ShareProductDetail(
          productDetails: _productDetails,
          onPressedCopy: () {
            onCopyTap(setState);
            Clipboard.setData(ClipboardData(text: _productDetails!.link ?? ""));
            // SocialShare.copyToClipboard(
            //     text: _productDetails!.link, image: "");
          },
          showCopied: _showCopied),
    );
  }

  onTapSellerChat() {
    context.showBottomSheet(
      child: ChatSellerSheet(
        sellerChatMessageController: sellerChatMessageController,
        sellerChatTitleController: sellerChatTitleController,
        onPressSendMessage: onPressSendMessage,
      ),
    );
  }

  loading() {
    showDialog(
        context: context,
        builder: (context) {
          loadingcontext = context;
          return AlertDialog(
              content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(
                width: 10,
              ),
              Text("${AppLocalizations.of(context)!.please_wait_ucf}"),
            ],
          ));
        });
  }

  showLoginWarning() {
    return ToastComponent.showDialog(
        AppLocalizations.of(context)!.you_need_to_log_in,
        gravity: Toast.center,
        duration: Toast.lengthLong);
  }

  onPressSendMessage() async {
    if (!is_logged_in.$) {
      showLoginWarning();
      return;
    }
    loading();
    var title = sellerChatTitleController.text.toString();
    var message = sellerChatMessageController.text.toString();

    if (title == "" || message == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.title_or_message_empty_warning,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      return;
    }

    var conversationCreateResponse = await ChatRepository()
        .getCreateConversationResponse(
            product_id: widget.id, title: title, message: message);

    Navigator.of(loadingcontext).pop();

    if (conversationCreateResponse.result == false) {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.could_not_create_conversation,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      return;
    }

    sellerChatTitleController.clear();
    sellerChatMessageController.clear();
    setState(() {});

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Chat(
        conversation_id: conversationCreateResponse.conversation_id,
        messenger_name: conversationCreateResponse.shop_name,
        messenger_title: conversationCreateResponse.title,
        messenger_image: conversationCreateResponse.shop_logo,
      );
    })).then((value) {
      onPopped(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    SnackBar _addedToCartSnackbar = SnackBar(
      content: Text(
        AppLocalizations.of(context)!.added_to_cart,
        style: TextStyle(
            fontFamily: app_mobile_language.$ == 'en'
                ? "PublicSansSerif"
                : AssetsArFonts.medium,
            color: MyTheme.font_grey),
      ),
      backgroundColor: MyTheme.soft_accent_color,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: AppLocalizations.of(context)!.show_cart_all_capital,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Cart(has_bottomnav: false);
          })).then((value) {
            onPopped(value);
          });
        },
        textColor: MyTheme.accent_color,
        disabledTextColor: Colors.grey,
      ),
    );

    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
          extendBody: true,
          bottomNavigationBar: BottomButtonNav(
            onPressAddToCart: () {
              onPressAddToCart(context, _addedToCartSnackbar);
            },
            onPressBuyNow: () {
              onPressBuyNow(context);
            },
            onPressStore: () {
              context.pop();
            },
            onPressStar: () {
              onWishTap();
            },
            isStar: _isInWishList,
            onPressChat: () {
              context.showBottomSheet(
                child: ChatSellerSheet(
                  sellerChatMessageController: sellerChatMessageController,
                  sellerChatTitleController: sellerChatTitleController,
                  onPressSendMessage: onPressSendMessage,
                ),
              );
            },
          ),

          //appBar: buildAppBar(statusBarHeight, context),
          body: RefreshIndicator(
            color: MyTheme.accent_color,
            backgroundColor: Colors.white,
            onRefresh: _onPageRefresh,
            child: CustomScrollView(
              controller: _mainScrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: <Widget>[
                SliverAppBar(
                  elevation: 0,
                  backgroundColor: Colors.white.withOpacity(opacity),
                  pinned: true,
                  automaticallyImplyLeading: false,
                  //titleSpacing: 0,
                  title: Row(
                    children: [
                      Builder(
                        builder: (context) => InkWell(
                          onTap: () {
                            return Navigator.of(context).pop();
                          },
                          child: Container(
                            decoration: BoxDecorations
                                .buildCircularButtonDecoration_1(),
                            width: 36,
                            height: 36,
                            child: Center(
                              child: Icon(
                                CupertinoIcons.arrow_left,
                                color: MyTheme.dark_font_grey,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),

                      //Show product name in appbar
                      AnimatedOpacity(
                        opacity: _scrollPosition > 350 ? 1 : 0,
                        duration: Duration(milliseconds: 200),
                        child: Container(
                          padding: EdgeInsets.only(left: 8),
                          width: DeviceInfo(context).width! / 3,
                          child: Text(
                            "${_productDetails != null ? _productDetails!.name : ''}",
                            style: TextStyle(
                                fontFamily: app_mobile_language.$ == 'en'
                                    ? "PublicSansSerif"
                                    : AssetsArFonts.medium,
                                color: MyTheme.dark_font_grey,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Spacer(),
                      InkWell(
                        onTap: () {
                          context.push(Cart(has_bottomnav: false));
                        },
                        child: Container(
                          decoration:
                              BoxDecorations.buildCircularButtonDecoration_1(),
                          width: 36,
                          height: 36,
                          padding: EdgeInsets.all(8),
                          child: badges.Badge(
                            badgeStyle: badges.BadgeStyle(
                              shape: badges.BadgeShape.circle,
                              badgeColor: MyTheme.accent_color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            badgeAnimation: badges.BadgeAnimation.slide(
                              toAnimate: true,
                            ),
                            stackFit: StackFit.loose,
                            child: Image.asset(
                              "assets/cart.png",
                              color: MyTheme.dark_font_grey,
                              height: 16,
                            ),
                            badgeContent: Consumer<CartCounter>(
                              builder: (context, cart, child) {
                                return Text(
                                  "${cart.cartCounter}",
                                  style: TextStyle(
                                      fontFamily: app_mobile_language.$ == 'en'
                                          ? "PublicSansSerif"
                                          : AssetsArFonts.medium,
                                      fontSize: 12,
                                      color: Colors.white),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      InkWell(
                        onTap: () {
                          onPressShare(context);
                        },
                        child: Container(
                          decoration:
                              BoxDecorations.buildCircularButtonDecoration_1(),
                          width: 36,
                          height: 36,
                          child: Center(
                            child: Icon(
                              Icons.share_outlined,
                              color: MyTheme.dark_font_grey,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      InkWell(
                        onTap: () {
                          onWishTap();
                        },
                        child: Container(
                          decoration:
                              BoxDecorations.buildCircularButtonDecoration_1(),
                          width: 36,
                          height: 36,
                          child: Center(
                            child: Icon(
                              Icons.favorite,
                              color: _isInWishList
                                  ? Color.fromRGBO(230, 46, 4, 1)
                                  : MyTheme.dark_font_grey,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                    ],
                  ),
                  expandedHeight: 375.0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: buildProductSliderImageSection(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    //padding: EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecorations.buildBoxDecoration_1(),
                    margin: EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              EdgeInsets.only(top: 14, left: 14, right: 14),
                          child: _productDetails != null
                              ? Text(
                                  _productDetails!.name!,
                                  style: TextStyles.smallTitleTexStyle(),
                                  maxLines: 2,
                                )
                              : ShimmerHelper().buildBasicShimmer(
                                  height: 30.0,
                                ),
                        ),
                        Padding(
                          padding:
                              EdgeInsets.only(top: 14, left: 14, right: 14),
                          child: _productDetails != null
                              ? buildRatingAndWishButtonRow()
                              : ShimmerHelper().buildBasicShimmer(
                                  height: 30.0,
                                ),
                        ),
                        if (_productDetails != null &&
                            _productDetails!.estShippingTime != null &&
                            _productDetails!.estShippingTime! > 0)
                          Padding(
                            padding:
                                EdgeInsets.only(top: 14, left: 14, right: 14),
                            child: _productDetails != null
                                ? buildShippingTime()
                                : ShimmerHelper().buildBasicShimmer(
                                    height: 30.0,
                                  ),
                          ),

                        Padding(
                          padding:
                              EdgeInsets.only(top: 14, left: 14, right: 14),
                          child: _productDetails != null
                              ? buildMainPriceRow()
                              : ShimmerHelper().buildBasicShimmer(
                                  height: 30.0,
                                ),
                        ),
                        Visibility(
                          visible: club_point_addon_installed.$,
                          child: Padding(
                            padding:
                                EdgeInsets.only(top: 14, left: 14, right: 14),
                            child: _productDetails != null
                                ? buildClubPointRow()
                                : ShimmerHelper().buildBasicShimmer(
                                    height: 30.0,
                                  ),
                          ),
                        ),
                        Padding(
                          padding:
                              EdgeInsets.only(top: 14, left: 14, right: 14),
                          child: _productDetails != null
                              ? buildBrandRow()
                              : ShimmerHelper().buildBasicShimmer(
                                  height: 50.0,
                                ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: _productDetails != null
                              ? buildSellerRow(context)
                              : ShimmerHelper().buildBasicShimmer(
                                  height: 50.0,
                                ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              top: 14,
                              left: app_language_rtl.$! ? 0 : 14,
                              right: app_language_rtl.$! ? 14 : 0),
                          child: _productDetails != null
                              ? buildChoiceOptionList()
                              : buildVariantShimmers(),
                        ),
                        Padding(
                          padding:
                              EdgeInsets.only(top: 14, left: 14, right: 14),
                          child: _productDetails != null
                              ? (_colorList.length > 0
                                  ? buildColorRow()
                                  : Container())
                              : ShimmerHelper().buildBasicShimmer(
                                  height: 30.0,
                                ),
                        ),

                        ///whole sale
                        Visibility(
                          visible: whole_sale_addon_installed.$,
                          child: Padding(
                            padding:
                                EdgeInsets.only(top: 14, left: 14, right: 14),
                            child: _productDetails != null
                                ? _productDetails!.wholesale!.isNotEmpty
                                    ? buildWholeSaleQuantityPrice()
                                    : SizedBox.shrink()
                                : ShimmerHelper().buildBasicShimmer(
                                    height: 30.0,
                                  ),
                          ),
                        ),
                        Padding(
                          padding:
                              EdgeInsets.only(top: 14, left: 14, right: 14),
                          child: _productDetails != null
                              ? buildQuantityRow()
                              : ShimmerHelper().buildBasicShimmer(
                                  height: 30.0,
                                ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 14, bottom: 14),
                          child: _productDetails != null
                              ? buildTotalPriceRow()
                              : ShimmerHelper().buildBasicShimmer(
                                  height: 30.0,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: MyTheme.white,
                          margin: EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16.0,
                                  20.0,
                                  16.0,
                                  0.0,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.description_ucf,
                                  style: TextStyle(
                                      fontFamily: app_mobile_language.$ == 'en'
                                          ? "PublicSansSerif"
                                          : AssetsArFonts.medium,
                                      color: MyTheme.dark_font_grey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16.0,
                                  0.0,
                                  8.0,
                                  8.0,
                                ),
                                child: _productDetails != null
                                    ? buildExpandableDescription()
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0, vertical: 8.0),
                                        child:
                                            ShimmerHelper().buildBasicShimmer(
                                          height: 60.0,
                                        )),
                              ),
                            ],
                          ),
                        ),
                        divider(),
                        InkWell(
                          onTap: () {
                            if (_productDetails!.video_link == "") {
                              ToastComponent.showDialog(
                                  AppLocalizations.of(context)!
                                      .video_not_available,
                                  gravity: Toast.center,
                                  duration: Toast.lengthLong);
                              return;
                            }

                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return VideoDescription(
                                url: _productDetails!.video_link,
                              );
                            })).then((value) {
                              onPopped(value);
                            });
                          },
                          child: Container(
                            color: MyTheme.white,
                            height: 48,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18.0,
                                14.0,
                                18.0,
                                14.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.video_ucf,
                                    style: TextStyle(
                                        fontFamily:
                                            app_mobile_language.$ == 'en'
                                                ? "PublicSansSerif"
                                                : AssetsArFonts.medium,
                                        color: MyTheme.dark_font_grey,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Spacer(),
                                  Image.asset(
                                    "assets/arrow.png",
                                    height: 11,
                                    width: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        divider(),
                        InkWell(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return ProductReviews(id: widget.id);
                            })).then((value) {
                              onPopped(value);
                            });
                          },
                          child: Container(
                            color: MyTheme.white,
                            height: 48,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18.0,
                                14.0,
                                18.0,
                                14.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.reviews_ucf,
                                    style: TextStyle(
                                        fontFamily:
                                            app_mobile_language.$ == 'en'
                                                ? "PublicSansSerif"
                                                : AssetsArFonts.medium,
                                        color: MyTheme.dark_font_grey,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Spacer(),
                                  Image.asset(
                                    "assets/arrow.png",
                                    height: 11,
                                    width: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        divider(),
                        InkWell(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return CommonWebviewScreen(
                                url:
                                    "${AppConfig.RAW_BASE_URL}/mobile-page/seller-policy",
                                page_name: AppLocalizations.of(context)!
                                    .seller_policy_ucf,
                              );
                            }));
                          },
                          child: Container(
                            color: MyTheme.white,
                            height: 48,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18.0,
                                14.0,
                                18.0,
                                14.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .seller_policy_ucf,
                                    style: TextStyle(
                                        fontFamily:
                                            app_mobile_language.$ == 'en'
                                                ? "PublicSansSerif"
                                                : AssetsArFonts.medium,
                                        color: MyTheme.dark_font_grey,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Spacer(),
                                  Image.asset(
                                    "assets/arrow.png",
                                    height: 11,
                                    width: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        divider(),
                        InkWell(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return CommonWebviewScreen(
                                url:
                                    "${AppConfig.RAW_BASE_URL}/mobile-page/return-policy",
                                page_name: AppLocalizations.of(context)!
                                    .return_policy_ucf,
                              );
                            }));
                          },
                          child: Container(
                            color: MyTheme.white,
                            height: 48,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18.0,
                                14.0,
                                18.0,
                                14.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .return_policy_ucf,
                                    style: TextStyle(
                                        fontFamily:
                                            app_mobile_language.$ == 'en'
                                                ? "PublicSansSerif"
                                                : AssetsArFonts.medium,
                                        color: MyTheme.dark_font_grey,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Spacer(),
                                  Image.asset(
                                    "assets/arrow.png",
                                    height: 11,
                                    width: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        divider(),
                        InkWell(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return CommonWebviewScreen(
                                url:
                                    "${AppConfig.RAW_BASE_URL}/mobile-page/support-policy",
                                page_name: AppLocalizations.of(context)!
                                    .support_policy_ucf,
                              );
                            }));
                          },
                          child: Container(
                            color: MyTheme.white,
                            height: 48,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18.0,
                                14.0,
                                18.0,
                                14.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .support_policy_ucf,
                                    style: TextStyle(
                                        fontFamily:
                                            app_mobile_language.$ == 'en'
                                                ? "PublicSansSerif"
                                                : AssetsArFonts.medium,
                                        color: MyTheme.dark_font_grey,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Spacer(),
                                  Image.asset(
                                    "assets/arrow.png",
                                    height: 11,
                                    width: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        divider(),
                      ]),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        18.0,
                        24.0,
                        18.0,
                        0.0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!
                            .products_you_may_also_like,
                        style: TextStyle(
                            fontFamily: app_mobile_language.$ == 'en'
                                ? "PublicSansSerif"
                                : AssetsArFonts.medium,
                            color: MyTheme.dark_font_grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    buildProductsMayLikeList()
                  ]),
                ),

                //Top selling product
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        18.0,
                        24.0,
                        18.0,
                        0.0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.top_selling_products_ucf,
                        style: TextStyle(
                            fontFamily: app_mobile_language.$ == 'en'
                                ? "PublicSansSerif"
                                : AssetsArFonts.medium,
                            color: MyTheme.dark_font_grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        0.0,
                        16.0,
                        0.0,
                      ),
                      child: buildTopSellingProductList(),
                    ),
                    Container(
                      height: 83,
                    )
                  ]),
                )
              ],
            ),
          )),
    );
  }

  Widget buildSellerRow(BuildContext context) {
    //print("sl:" +  _productDetails!.shop_logo);
    return Container(
      color: MyTheme.light_grey,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          _productDetails!.added_by == "admin"
              ? Container()
              : InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SellerDetails(
                                  id: _productDetails!.shop_id,
                                )));
                  },
                  child: Padding(
                    padding: app_language_rtl.$!
                        ? EdgeInsets.only(left: 8.0)
                        : EdgeInsets.only(right: 8.0),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                            color: Color.fromRGBO(112, 112, 112, .3), width: 1),
                        //shape: BoxShape.rectangle,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.0),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder.png',
                          image: _productDetails!.shop_logo!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
          Container(
            width: MediaQuery.of(context).size.width * (.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.seller_ucf,
                    style: TextStyle(
                      fontFamily: app_mobile_language.$ == 'en'
                          ? "PublicSansSerif"
                          : AssetsArFonts.medium,
                      color: Color.fromRGBO(153, 153, 153, 1),
                    )),
                Text(
                  _productDetails!.shop_name!,
                  style: TextStyle(
                      fontFamily: app_mobile_language.$ == 'en'
                          ? "PublicSansSerif"
                          : AssetsArFonts.medium,
                      color: MyTheme.font_grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
          Spacer(),
          Visibility(
            visible: conversation_system_status.$,
            child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecorations.buildCircularButtonDecoration_1(),
                child: Row(
                  children: [
                    InkWell(
                        onTap: () {
                          if (is_logged_in == false) {
                            ToastComponent.showDialog("You need to log in",
                                gravity: Toast.center,
                                duration: Toast.lengthLong);
                            return;
                          }

                          onTapSellerChat();
                        },
                        child: Image.asset('assets/chat.png',
                            height: 16, width: 16, color: MyTheme.dark_grey)),
                  ],
                )),
          )
        ],
      ),
    );
  }

  Widget buildTotalPriceRow() {
    return Container(
      height: 40,
      color: MyTheme.amber,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            child: Padding(
              padding: app_language_rtl.$!
                  ? EdgeInsets.only(left: 8.0)
                  : EdgeInsets.only(right: 8.0),
              child: Container(
                width: 75,
                child: Text(
                  AppLocalizations.of(context)!.total_price_ucf,
                  style: TextStyle(
                      fontFamily: app_mobile_language.$ == 'en'
                          ? "PublicSansSerif"
                          : AssetsArFonts.medium,
                      color: Color.fromRGBO(153, 153, 153, 1),
                      fontSize: 10),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text(
              SystemConfig.systemCurrency != null
                  ? _totalPrice.toString().replaceAll(
                      SystemConfig.systemCurrency!.code!,
                      SystemConfig.systemCurrency!.symbol!)
                  : SystemConfig.systemCurrency!.symbol! +
                      _totalPrice.toString(),
              style: TextStyle(
                  fontFamily: app_mobile_language.$ == 'en'
                      ? "PublicSansSerif"
                      : AssetsArFonts.medium,
                  color: MyTheme.accent_color,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }

  Row buildQuantityRow() {
    return Row(
      children: [
        Padding(
          padding: app_language_rtl.$!
              ? EdgeInsets.only(left: 8.0)
              : EdgeInsets.only(right: 8.0),
          child: Container(
            width: 75,
            child: Text(
              AppLocalizations.of(context)!.quantity_ucf,
              style: TextStyle(
                  fontFamily: app_mobile_language.$ == 'en'
                      ? "PublicSansSerif"
                      : AssetsArFonts.medium,
                  color: Color.fromRGBO(153, 153, 153, 1)),
            ),
          ),
        ),
        Container(
          height: 36,
          width: 120,
          /*decoration: BoxDecoration(
              border:
                  Border.all(color: Color.fromRGBO(222, 222, 222, 1), width: 1),
              borderRadius: BorderRadius.circular(36.0),
              color: Colors.white),*/
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              buildQuantityDownButton(),
              /* Container(
                  width: 36,
                  child: Center(
                      child: Text(
                    _quantity.toString(),
                    style: TextStyle(fontSize: 18, color: MyTheme.dark_grey),
                  ))),*/
              Container(
                  width: 36,
                  child: Center(
                      child: QuantityInputField.show(quantityText,
                          isDisable: _quantity == 0, onSubmitted: () {
                    _quantity = int.parse(quantityText.text);
                    print(_quantity);
                    fetchAndSetVariantWiseInfo();
                  }))),
              buildQuantityUpButton()
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "($_stock_txt)",
            style: TextStyle(
                fontFamily: app_mobile_language.$ == 'en'
                    ? "PublicSansSerif"
                    : AssetsArFonts.medium,
                color: Color.fromRGBO(152, 152, 153, 1),
                fontSize: 14),
          ),
        ),
      ],
    );
  }

  TextEditingController quantityText = TextEditingController(text: "0");

  Padding buildVariantShimmers() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        0.0,
        8.0,
        0.0,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 30.0, width: 60),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildChoiceOptionList() {
    return ListView.builder(
      itemCount: _productDetails!.choice_options!.length,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: buildChoiceOpiton(_productDetails!.choice_options, index),
        );
      },
    );
  }

  buildChoiceOpiton(choiceOptions, choiceOptionsIndex) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0.0,
        14.0,
        0.0,
        0.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: app_language_rtl.$!
                ? EdgeInsets.only(left: 8.0)
                : EdgeInsets.only(right: 8.0),
            child: Container(
              width: 75,
              child: Text(
                choiceOptions[choiceOptionsIndex].title,
                style: TextStyle(
                    fontFamily: app_mobile_language.$ == 'en'
                        ? "PublicSansSerif"
                        : AssetsArFonts.medium,
                    color: Color.fromRGBO(153, 153, 153, 1)),
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width - (107 + 45),
            child: Scrollbar(
              controller: _variantScrollController,
              thumbVisibility: false,
              child: Wrap(
                children: List.generate(
                    choiceOptions[choiceOptionsIndex].options.length,
                    (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          width: 75,
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: buildChoiceItem(
                              choiceOptions[choiceOptionsIndex].options[index],
                              choiceOptionsIndex,
                              index),
                        ))),
              ),

              /*ListView.builder(
                itemCount: choice_options[choice_options_index].options.length,
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return
                },
              ),*/
            ),
          )
        ],
      ),
    );
  }

  buildChoiceItem(option, choiceOptionsIndex, index) {
    return Padding(
      padding: app_language_rtl.$!
          ? EdgeInsets.only(left: 8.0)
          : EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          _onVariantChange(choiceOptionsIndex, option);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: _selectedChoices[choiceOptionsIndex] == option
                    ? MyTheme.accent_color
                    : MyTheme.noColor,
                width: 1.5),
            borderRadius: BorderRadius.circular(3.0),
            color: MyTheme.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                spreadRadius: 1,
                offset: Offset(0.0, 3.0), // shadow direction: bottom right
              )
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
            child: Center(
              child: Text(
                option,
                style: TextStyle(
                    fontFamily: app_mobile_language.$ == 'en'
                        ? "PublicSansSerif"
                        : AssetsArFonts.medium,
                    color: _selectedChoices[choiceOptionsIndex] == option
                        ? MyTheme.accent_color
                        : Color.fromRGBO(224, 224, 225, 1),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  buildColorRow() {
    return Row(
      children: [
        Padding(
          padding: app_language_rtl.$!
              ? EdgeInsets.only(left: 8.0)
              : EdgeInsets.only(right: 8.0),
          child: Container(
            width: 75,
            child: Text(
              AppLocalizations.of(context)!.color_ucf,
              style: TextStyle(
                  fontFamily: app_mobile_language.$ == 'en'
                      ? "PublicSansSerif"
                      : AssetsArFonts.medium,
                  color: Color.fromRGBO(153, 153, 153, 1)),
            ),
          ),
        ),
        Container(
          alignment: app_language_rtl.$!
              ? Alignment.centerRight
              : Alignment.centerLeft,
          height: 40,
          width: MediaQuery.of(context).size.width - (107 + 44),
          child: Scrollbar(
            controller: _colorScrollController,
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return SizedBox(
                  width: 10,
                );
              },
              itemCount: _colorList.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildColorItem(index),
                  ],
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget buildColorItem(index) {
    return InkWell(
      onTap: () {
        _onColorChange(index);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        width: _selectedColorIndex == index ? 30 : 25,
        height: _selectedColorIndex == index ? 30 : 25,
        decoration: BoxDecoration(
          // border: Border.all(
          //     color: _selectedColorIndex == index
          //         ? Colors.purple
          //         : Colors.white,
          //     width: 1),
          borderRadius: BorderRadius.circular(16.0),
          color: ColorHelper.getColorFromColorCode(_colorList[index]),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(_selectedColorIndex == index ? 0.25 : 0.12),
              blurRadius: 10,
              spreadRadius: 2.0,
              offset: Offset(0.0, 6.0), // shadow direction: bottom right
            )
          ],
        ),
        child: _selectedColorIndex == index
            ? buildColorCheckerContainer()
            : Container(
                height: 25,
              ),
        /*Padding(
          padding: const EdgeInsets.all(2.0),
          child: Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
                // border: Border.all(
                //     color: Color.fromRGBO(222, 222, 222, 1), width: 1),
               // borderRadius: BorderRadius.circular(16.0),
                color: ColorHelper.getColorFromColorCode(_colorList[index])),
            child: _selectedColorIndex == index
                ? buildColorCheckerContainer()
                : Container(),
          ),
        ),*/
      ),
    );
  }

  buildColorCheckerContainer() {
    return Padding(
        padding: const EdgeInsets.all(3),
        child: /*Icon(Icons.check, color: Colors.white, size: 16),*/
            Image.asset(
          "assets/white_tick.png",
          width: 16,
          height: 16,
        ));
  }

  Widget buildWholeSaleQuantityPrice() {
    return DataTable(
      // clipBehavior:Clip.antiAliasWithSaveLayer,
      columnSpacing: DeviceInfo(context).width! * 0.125,

      columns: [
        DataColumn(
            label: Text(LangText(context).local.min_qty_ucf,
                style: TextStyle(
                    fontFamily: app_mobile_language.$ == 'en'
                        ? "PublicSansSerif"
                        : AssetsArFonts.medium,
                    fontSize: 12,
                    color: MyTheme.dark_grey))),
        DataColumn(
            label: Text(LangText(context).local.max_qty_ucf,
                style: TextStyle(
                    fontFamily: app_mobile_language.$ == 'en'
                        ? "PublicSansSerif"
                        : AssetsArFonts.medium,
                    fontSize: 12,
                    color: MyTheme.dark_grey))),
        DataColumn(
            label: Text(LangText(context).local.unit_price_ucf,
                style: TextStyle(
                    fontFamily: app_mobile_language.$ == 'en'
                        ? "PublicSansSerif"
                        : AssetsArFonts.medium,
                    fontSize: 12,
                    color: MyTheme.dark_grey))),
      ],
      rows: List<DataRow>.generate(
        _productDetails!.wholesale!.length,
        (index) {
          return DataRow(cells: <DataCell>[
            DataCell(
              Text(
                '${_productDetails!.wholesale![index].minQty.toString()}',
                style: TextStyle(
                    color: Color.fromRGBO(152, 152, 153, 1), fontSize: 12),
              ),
            ),
            DataCell(
              Text(
                '${_productDetails!.wholesale![index].maxQty.toString()}',
                style: TextStyle(
                    fontFamily: app_mobile_language.$ == 'en'
                        ? "PublicSansSerif"
                        : AssetsArFonts.medium,
                    color: Color.fromRGBO(152, 152, 153, 1),
                    fontSize: 12),
              ),
            ),
            DataCell(
              Text(
                convertPrice(
                    _productDetails!.wholesale![index].price.toString()),
                style: TextStyle(
                    fontFamily: app_mobile_language.$ == 'en'
                        ? "PublicSansSerif"
                        : AssetsArFonts.medium,
                    color: Color.fromRGBO(152, 152, 153, 1),
                    fontSize: 12),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget buildClubPointRow() {
    return Container(
      constraints: BoxConstraints(maxWidth: 130),
      //width: ,
      decoration: BoxDecoration(
          //border: Border.all(color: MyTheme.golden, width: 1),
          borderRadius: BorderRadius.circular(6.0),
          color:
              //Colors.red,),
              Color.fromRGBO(253, 235, 212, 1)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/clubpoint.png",
                  width: 18,
                  height: 12,
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  AppLocalizations.of(context)!.club_point_ucf,
                  style: TextStyle(
                      fontFamily: app_mobile_language.$ == 'en'
                          ? "PublicSansSerif"
                          : AssetsArFonts.medium,
                      color: MyTheme.font_grey,
                      fontSize: 10),
                ),
              ],
            ),
            Text(
              _productDetails!.earn_point.toString(),
              style: TextStyle(
                  fontFamily: app_mobile_language.$ == 'en'
                      ? "PublicSansSerif"
                      : AssetsArFonts.medium,
                  color: MyTheme.golden,
                  fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }

  Row buildMainPriceRow() {
    return Row(
      children: [
        Text(
          SystemConfig.systemCurrency != null
              ? _singlePriceString.replaceAll(SystemConfig.systemCurrency!.code,
                  SystemConfig.systemCurrency!.symbol)
              : _singlePriceString,
          // _singlePriceString,
          style: TextStyle(
              fontFamily: app_mobile_language.$ == 'en'
                  ? "PublicSansSerif"
                  : AssetsArFonts.medium,
              color: MyTheme.accent_color,
              fontSize: 16.0,
              fontWeight: FontWeight.w600),
        ),
        Visibility(
          visible: _productDetails!.has_discount!,
          child: Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(
                SystemConfig.systemCurrency != null
                    ? _productDetails!.stroked_price!.replaceAll(
                        SystemConfig.systemCurrency!.code!,
                        SystemConfig.systemCurrency!.symbol!)
                    : _productDetails!.stroked_price!,
                style: TextStyle(
                  fontFamily: app_mobile_language.$ == 'en'
                      ? "PublicSansSerif"
                      : AssetsArFonts.medium,
                  decoration: TextDecoration.lineThrough,
                  color: Color.fromRGBO(224, 224, 225, 1),
                  fontSize: 12.0,
                  fontWeight: FontWeight.normal,
                )),
          ),
        ),
        Visibility(
          visible: _productDetails!.has_discount!,
          child: Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(
              "${_productDetails!.discount}",
              style: TextStyles.largeBoldAccentTexStyle(),
            ),
          ),
        ),
        Text(
          "/${_productDetails!.unit}",
          // _singlePriceString,
          style: TextStyle(
              fontFamily: app_mobile_language.$ == 'en'
                  ? "PublicSansSerif"
                  : AssetsArFonts.medium,
              color: MyTheme.accent_color,
              fontSize: 16.0,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  AppBar buildAppBar(double statusBarHeight, BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Container(
        height: kToolbarHeight +
            statusBarHeight -
            (MediaQuery.of(context).viewPadding.top > 40 ? 32.0 : 16.0),
        //MediaQuery.of(context).viewPadding.top is the statusbar height, with a notch phone it results almost 50, without a notch it shows 24.0.For safety we have checked if its greater than thirty
        child: Container(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.only(top: 22.0),
              child: Text(
                _appbarPriceString!,
                style: TextStyle(
                    fontFamily: app_mobile_language.$ == 'en'
                        ? "PublicSansSerif"
                        : AssetsArFonts.medium,
                    fontSize: 16,
                    color: MyTheme.font_grey),
              ),
            )),
      ),
      elevation: 0.0,
      titleSpacing: 0,
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          child: IconButton(
            icon: Icon(Icons.share_outlined, color: MyTheme.dark_grey),
            onPressed: () {
              onPressShare(context);
            },
          ),
        ),
      ],
    );
  }

  buildRatingAndWishButtonRow() {
    return Row(
      children: [
        RatingBar(
          itemSize: 15.0,
          ignoreGestures: true,
          initialRating: double.parse(_productDetails!.rating.toString()),
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          ratingWidget: RatingWidget(
            full: Icon(Icons.star, color: Colors.amber),
            half: Icon(Icons.star_half, color: Colors.amber),
            empty: Icon(Icons.star, color: Color.fromRGBO(224, 224, 225, 1)),
          ),
          itemPadding: EdgeInsets.only(right: 1.0),
          onRatingUpdate: (rating) {
            //print(rating);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "(" + _productDetails!.rating_count.toString() + ")",
            style: TextStyle(
                fontFamily: app_mobile_language.$ == 'en'
                    ? "PublicSansSerif"
                    : AssetsArFonts.medium,
                color: Color.fromRGBO(152, 152, 153, 1),
                fontSize: 10),
          ),
        ),
      ],
    );
  }

  buildShippingTime() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Estimate Shipping Time",
            style: TextStyle(
              color: Color.fromRGBO(152, 152, 153, 1),
              fontSize: 10,
              fontFamily: app_mobile_language.$ == 'en'
                  ? "PublicSansSerif"
                  : AssetsArFonts.medium,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "${_productDetails!.estShippingTime} Days",
            style: TextStyle(
              color: Color.fromRGBO(152, 152, 153, 1),
              fontSize: 10,
              fontFamily: app_mobile_language.$ == 'en'
                  ? "PublicSansSerif"
                  : AssetsArFonts.medium,
            ),
          ),
        ),
      ],
    );
  }

  buildBrandRow() {
    return _productDetails!.brand!.id! > 0
        ? InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return BrandProducts(
                  id: _productDetails!.brand!.id,
                  brand_name: _productDetails!.brand!.name,
                );
              }));
            },
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: Container(
                    width: 75,
                    child: Text(
                      AppLocalizations.of(context)!.brand_ucf,
                      style: TextStyle(
                          fontFamily: app_mobile_language.$ == 'en'
                              ? "PublicSansSerif"
                              : AssetsArFonts.medium,
                          color: Color.fromRGBO(
                            153,
                            153,
                            153,
                            1,
                          ),
                          fontSize: 10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    _productDetails!.brand!.name!,
                    style: TextStyle(
                        fontFamily: app_mobile_language.$ == 'en'
                            ? "PublicSansSerif"
                            : AssetsArFonts.medium,
                        color: MyTheme.font_grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10),
                  ),
                ),
                /*Spacer(),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: Color.fromRGBO(112, 112, 112, .3), width: 1),
                    //shape: BoxShape.rectangle,
                  ),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: _productDetails!.brand.logo,
                        fit: BoxFit.contain,
                      )),
                ),*/
              ],
            ),
          )
        : Container();
  }

  buildExpandableDescription() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: DeviceInfo(context).width,
            height: webViewHeight,
            child: WebViewWidget(
              controller: controller,
            ),
          ),
          Btn.basic(
              onPressed: () async {
                if (webViewHeight == 50) {
                  webViewHeight = double.parse(
                    (await controller.runJavaScriptReturningResult(
                            "document.getElementById('scaled-frame').clientHeight"))
                        .toString(),
                  );
                  print(webViewHeight);
                  print(MediaQuery.of(context).devicePixelRatio);

                  webViewHeight = (webViewHeight /
                          MediaQuery.of(context).devicePixelRatio) +
                      50;
                  print(webViewHeight);
                } else {
                  webViewHeight = 50;
                }
                setState(() {});
              },
              child: Text(
                webViewHeight == 50 ? "Show More..." : "Less",
                style: TextStyle(
                    fontFamily: app_mobile_language.$ == 'en'
                        ? "PublicSansSerif"
                        : AssetsArFonts.medium,
                    color: Colors.black),
              ))
        ],
      ),
    );
    /*ExpandableNotifier(
        child: ScrollOnExpand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expandable(
            collapsed: Container(
                height: 50, child: Html(data: _productDetails!.description)),
            expanded: Container(child: Html(
              data: _productDetails!.description,
            )
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Builder(
                builder: (context) {
                  var controller = ExpandableController.of(context)!;
                  return Btn.basic(
                    child: Text(
                      !controller.expanded
                          ? AppLocalizations.of(context)!.view_more_ucf
                          : AppLocalizations.of(context)!.show_less_ucf,
                      style: TextStyle(color: MyTheme.font_grey, fontSize: 11),
                    ),
                    onPressed: () {
                      controller.toggle();
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ));*/
  }

  buildTopSellingProductList() {
    if (_topProductInit == false && _topProducts.length == 0) {
      return Column(
        children: [
          Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                height: 75.0,
              )),
          Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                height: 75.0,
              )),
          Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                height: 75.0,
              )),
        ],
      );
    } else if (_topProducts.length > 0) {
      return SingleChildScrollView(
        child: ListView.separated(
          separatorBuilder: (context, index) => SizedBox(
            height: 14,
          ),
          itemCount: _topProducts.length,
          scrollDirection: Axis.vertical,
          padding: EdgeInsets.only(top: 14),
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return ListProductCard(
                id: _topProducts[index].id,
                image: _topProducts[index].thumbnail_image,
                name: _topProducts[index].name,
                main_price: _topProducts[index].main_price,
                stroked_price: _topProducts[index].stroked_price,
                has_discount: _topProducts[index].has_discount);
          },
        ),
      );
    } else {
      return Container(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!
                .no_top_selling_products_from_this_seller,
            style: TextStyle(
              color: MyTheme.font_grey,
              fontFamily: app_mobile_language.$ == 'en'
                  ? "PublicSansSerif"
                  : AssetsArFonts.medium,
            ),
          ),
        ),
      );
    }
  }

  buildProductsMayLikeList() {
    if (_relatedProductInit == false && _relatedProducts.length == 0) {
      return Row(
        children: [
          Padding(
              padding: app_language_rtl.$!
                  ? EdgeInsets.only(left: 8.0)
                  : EdgeInsets.only(right: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                  height: 120.0,
                  width: (MediaQuery.of(context).size.width - 32) / 3)),
          Padding(
              padding: app_language_rtl.$!
                  ? EdgeInsets.only(left: 8.0)
                  : EdgeInsets.only(right: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                  height: 120.0,
                  width: (MediaQuery.of(context).size.width - 32) / 3)),
          Padding(
              padding: const EdgeInsets.only(right: 0.0),
              child: ShimmerHelper().buildBasicShimmer(
                  height: 120.0,
                  width: (MediaQuery.of(context).size.width - 32) / 3)),
        ],
      );
    } else if (_relatedProducts.length > 0) {
      return SingleChildScrollView(
        child: SizedBox(
          height: 248,
          child: ListView.separated(
            separatorBuilder: (context, index) => SizedBox(
              width: 16,
            ),
            padding: const EdgeInsets.all(16),
            itemCount: _relatedProducts.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return MiniProductCard(
                  id: _relatedProducts[index].id,
                  image: _relatedProducts[index].thumbnail_image,
                  name: _relatedProducts[index].name,
                  main_price: _relatedProducts[index].main_price,
                  stroked_price: _relatedProducts[index].stroked_price,
                  is_wholesale: _relatedProducts[index].isWholesale,
                  discount: _relatedProducts[index].discount,
                  has_discount: _relatedProducts[index].has_discount);
            },
          ),
        ),
      );
    } else {
      return Container(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_related_product,
            style: TextStyle(
              color: MyTheme.font_grey,
              fontFamily: app_mobile_language.$ == 'en'
                  ? "PublicSansSerif"
                  : AssetsArFonts.medium,
            ),
          ),
        ),
      );
    }
  }

  buildQuantityUpButton() => Container(
        decoration: BoxDecorations.buildCircularButtonDecoration_1(),
        width: 36,
        child: IconButton(
            icon: Icon(Icons.add, size: 16, color: MyTheme.dark_grey),
            onPressed: () {
              if (_quantity! < _stock!) {
                _quantity = (_quantity!) + 1;
                setState(() {});
                //fetchVariantPrice();

                fetchAndSetVariantWiseInfo();
                // calculateTotalPrice();
              }
            }),
      );

  buildQuantityDownButton() => Container(
      decoration: BoxDecorations.buildCircularButtonDecoration_1(),
      width: 36,
      child: IconButton(
          icon: Icon(Icons.remove, size: 16, color: MyTheme.dark_grey),
          onPressed: () {
            if (_quantity! > 1) {
              _quantity = _quantity! - 1;
              setState(() {});
              // calculateTotalPrice();
              // fetchVariantPrice();
              fetchAndSetVariantWiseInfo();
            }
          }));

  openPhotoDialog(BuildContext context, path) => showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
                child: Stack(
              children: [
                PhotoView(
                  enableRotation: true,
                  heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
                  imageProvider: NetworkImage(path),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    decoration: ShapeDecoration(
                      color: MyTheme.medium_grey_50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                          topRight: Radius.circular(25),
                          topLeft: Radius.circular(25),
                        ),
                      ),
                    ),
                    width: 40,
                    height: 40,
                    child: IconButton(
                      icon: Icon(Icons.clear, color: MyTheme.white),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                    ),
                  ),
                ),
              ],
            )),
          );
        },
      );

  buildProductImageSection() {
    if (_productImageList.length == 0) {
      return Row(
        children: [
          Container(
            width: 40,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 40.0, width: 40.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 40.0, width: 40.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 40.0, width: 40.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper()
                      .buildBasicShimmer(height: 40.0, width: 40.0),
                ),
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: ShimmerHelper().buildBasicShimmer(
                height: 190.0,
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 250,
            width: 64,
            child: Scrollbar(
              controller: _imageScrollController,
              thumbVisibility: false,
              thickness: 4.0,
              child: Padding(
                padding: app_language_rtl.$!
                    ? EdgeInsets.only(left: 8.0)
                    : EdgeInsets.only(right: 8.0),
                child: ListView.builder(
                    itemCount: _productImageList.length,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      int itemIndex = index;
                      return GestureDetector(
                        onTap: () {
                          _currentImage = itemIndex;
                          print(_currentImage);
                          setState(() {});
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 2.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _currentImage == itemIndex
                                    ? MyTheme.accent_color
                                    : Color.fromRGBO(112, 112, 112, .3),
                                width: _currentImage == itemIndex ? 2 : 1),
                            //shape: BoxShape.rectangle,
                          ),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child:
                                  /*Image.asset(
                                        singleProduct.product_images[index])*/
                                  FadeInImage.assetNetwork(
                                placeholder: 'assets/placeholder.png',
                                image: _productImageList[index],
                                fit: BoxFit.contain,
                              )),
                        ),
                      );
                    }),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              openPhotoDialog(context, _productImageList[_currentImage]);
            },
            child: Container(
              height: 250,
              width: MediaQuery.of(context).size.width - 96,
              child: Container(
                  child: FadeInImage.assetNetwork(
                placeholder: 'assets/placeholder_rectangle.png',
                image: _productImageList[_currentImage],
                fit: BoxFit.scaleDown,
              )),
            ),
          ),
        ],
      );
    }
  }

  Widget buildProductSliderImageSection() {
    if (_productImageList.length == 0) {
      return ShimmerHelper().buildBasicShimmer(
        height: 190.0,
      );
    } else {
      return CarouselSlider(
        carouselController: _carouselController,
        options: CarouselOptions(
          aspectRatio: 355 / 375,
          viewportFraction: 1,
          initialPage: 0,
          // autoPlay: true,
          autoPlayInterval: Duration(seconds: 5),
          autoPlayAnimationDuration: Duration(milliseconds: 1000),
          autoPlayCurve: Curves.easeInExpo,
          enlargeCenterPage: false,
          scrollDirection: Axis.horizontal,
          onPageChanged: (index, reason) {
            print(index);
            setState(() {
              _currentImage = index;
            });
          },
        ),
        items: _productImageList.map((i) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                child: Stack(
                  children: <Widget>[
                    InkWell(
                      onTap: () {
                        openPhotoDialog(
                            context, _productImageList[_currentImage]);
                      },
                      child: Container(
                        height: double.infinity,
                        width: double.infinity,
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder_rectangle.png',
                          image: i,
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                    ),
                    Positioned(
                      // top: 10,
                      bottom: 10,
                      left: 5,
                      child: DownloadImageProduct(
                        name: "image",
                        url: i,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _productImageList.length,
                          (index) => Container(
                            width: 7.0,
                            height: 7.0,
                            margin: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImage == index
                                  ? MyTheme.font_grey
                                  : Colors.grey.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      );
    }
  }

  Widget divider() {
    return Container(
      color: MyTheme.light_grey,
      height: 5,
    );
  }

  String makeHtml(String string) {
    return """
<!DOCTYPE html>
<html>

<head>
    <link rel="stylesheet" href="${AppConfig.RAW_BASE_URL}/public/assets/css/vendors.css">
  <style>
  *{
  margin:0 !important;
  padding:0 !important;
  font-size:120% !important;
  
  }

    #scaled-frame {
    }
  </style>
</head>

<body id="main_id">
  <div id="scaled-frame">
$string
  </div>
</body>

</html>
""";
  }
}
