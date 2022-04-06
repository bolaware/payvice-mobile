import 'dart:math';
import 'dart:ui';
import 'package:country_code_picker/country_code.dart';
import 'package:flutter_sim_country_code/flutter_sim_country_code.dart';
import 'package:payvice_app/string_extensions.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:payvice_app/bloc/beneficiaries/bank_beneficiaries_bloc.dart';
import 'package:payvice_app/bloc/bloc_provider.dart';
import 'package:payvice_app/bloc/contacts/contacts_bloc.dart';
import 'package:payvice_app/data/local_contact.dart';
import 'package:payvice_app/data/response/beneficiaries/bank_beneficiaries_response.dart';
import 'package:payvice_app/data/response/contacts/contacts_response.dart';
import 'package:payvice_app/data/response_base.dart';
import 'package:payvice_app/routes/routes.dart';
import 'package:payvice_app/ui/customs/general_button.dart';
import 'package:payvice_app/ui/customs/icons/payvice_icons_icons.dart';
import 'package:payvice_app/ui/customs/leading_text_widget.dart';
import 'package:payvice_app/ui/customs/quick_actions_widget.dart';
import 'package:payvice_app/ui/screens/send/amount_screen.dart';
import 'package:payvice_app/ui/screens/send/payvice_friends_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({Key key}) : super(key: key);

  @override
  _SendScreenState createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {

  final contactsBloc = ContactsBloc();
  final bankBeneficiariesBloc = BankBeneficiariesBloc();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      bloc: contactsBloc,
      child: BlocProvider(
        bloc: bankBeneficiariesBloc,
        child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(
                    left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
                sliver: new SliverList(
                    delegate: new SliverChildListDelegate(
                      [
                        adverts(context),
                        _quickActions(context),
                        SizedBox(height: 16.0,),
                        _payViceContacts(),
                        SizedBox(height: 16.0,),
                      ],
                    )),
              ),
              StreamBuilder<BaseResponse<BankBeneficiaryResponse>>(
                  stream: bankBeneficiariesBloc.bankBeneficiaryResponseStream,
                  builder: (context, snapshot) {
                    if(snapshot.data is Success) {
                      final bankBeneficiaries = (snapshot.data as Success<BankBeneficiaryResponse>).getData().beneficaries.where((element) => element.destination == "Bank").toList();
                      if(bankBeneficiaries.isEmpty) {
                        return SliverToBoxAdapter(
                          child: SizedBox.shrink(),
                        );
                      }
                      return SliverList(
                          delegate: new SliverChildBuilderDelegate(
                                (BuildContext context, int index) {
                              if (index == 0) {
                                return _recentBeneficiariesTitle(context);
                              } else {
                                return _recentBeneficiaries(bankBeneficiaries[index - 1]);
                              }
                            },
                            childCount: bankBeneficiaries.length + 1,
                          ));
                    } else {
                      return SliverToBoxAdapter(
                        child: SizedBox.shrink(),
                      );
                    }
                  }
              ),
            ]
        ),
      ),
    );
  }

  Widget _recentBeneficiaries(Beneficiary beneficiary) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
            context, PayviceRouter.send_to_bank,
            arguments: beneficiary
        );
      },
      child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: LeadingText(
                      textWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              beneficiary.beneficiaryFullName, style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis,),
                            Text(
                              "${beneficiary.bankName} ${beneficiary.accountDetail}", style: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis,),
                          ],
                      ),
                      spacing: 16.0,
                      icon: Container(
                        padding: EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                            color: Colors.green.withAlpha(50),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22), bottomRight: Radius.circular(22))
                        ),
                        child: Icon(PayviceIcons.thunder, color: Colors.green),
                      ),
                  ),
                ),
                Divider()
              ],
            ),
    );
  }

  Text _recentBeneficiariesTitle(BuildContext context) {
    return Text(
      "Recent beneficiaries",
      style: Theme.of(context).textTheme.headline2.copyWith(fontSize: 16.0), textAlign: TextAlign.start,);
  }

  Widget adverts(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 5.0),
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              color: Theme.of(context).accentColor.withAlpha(80)
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.0),
                  child: Image.asset('images/noto_blue_wrapped-gift.png', width: 44, height: 44,),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Transfer money", style: Theme.of(context).textTheme.bodyText2.copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.0,),
                      Text("Quick bills, recurring bills. etc", style: Theme.of(context).textTheme.bodyText2.copyWith(color: Color(0xFF6E88A9)))
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top:0.0,
          right: 0.0,
          child: Visibility(
            visible: false,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 14.0),
              child: new InkWell(
                  child: Container(
                      height: 20.0,
                      width: 20.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white
                      ),
                      child: Icon(Icons.close, size: 16.0, color: Colors.black,)
                  ),
                  onTap: () {

                  }),
            ),
          ),
        )
      ],
    );
  }

  Column _quickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: QuickActionsWidget(
                  text: "Scan to Pay",
                  iconWidget: CircleAvatar(
                      radius: 24.0,
                      backgroundColor: Theme.of(context).accentColor.withAlpha(120),
                      child: Icon(PayviceIcons.barcode_scanner, color: Theme.of(context).accentColor,)),
                  clickListener: () {
                    Navigator.pushNamed(
                        context, PayviceRouter.coming_soon_screen
                    );
                  }
              ),
            ),
            SizedBox(width: 12.0,),
            Expanded(
              child: QuickActionsWidget(
                  text: "Send money",
                  iconWidget: CircleAvatar(
                      radius: 24.0,
                      backgroundColor: Theme.of(context).accentColor.withAlpha(120),
                      child: Icon(PayviceIcons.send, color: Theme.of(context).accentColor,)),
                clickListener: () {
                  Navigator.pushNamed(
                      context, PayviceRouter.send_options_screen
                  );
                },
              ),
            ),
          ],
        )
      ],
    );
  }

  @override
  void initState() {
    _fetchContacts();
    bankBeneficiariesBloc.getBeneficiaries();
    super.initState();
  }

  Widget _payViceContacts() {
    return StreamBuilder<List<LocalContact>>(
        stream: contactsBloc.stream,
        builder: (context, snapshot) {
          if (snapshot.data != null) {

            final friends = snapshot.data
                .where((element) => element is FriendData)
                .toList();

            if(friends.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Send money to friends", style: Theme.of(context).textTheme.headline2.copyWith(fontSize: 16.0), textAlign: TextAlign.start,),
                  Container(
                    height: 100,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                  context,
                                  PayviceRouter.payvice_friends,
                                  arguments: PayviceFriendsScreenArgument(
                                      selectedFriend: friends[index] as FriendData, isRequest: false
                                  )
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.all(8.0),
                              child: LeadingText(
                                textWidget: Text(
                                  "${(friends[index] as FriendData).firstName}", style: Theme.of(context).textTheme.bodyText2, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,),
                                icon: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundImage: NetworkImage(
                                          (friends[index] as FriendData).avatar ??
                                          "https://pickaface.net/gallery/avatar/klancaster577452311623266f9.png"
                                      ),
                                    ),
                                    Positioned(
                                      top: 0.0, right: 0.0,
                                      child: new InkWell(
                                          child: Container(
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Theme.of(context).primaryColor
                                              ),
                                              child: Icon(Icons.check, size: 16.0, color: Colors.white,)
                                          ),
                                          onTap: () {

                                          }),
                                    )
                                  ],
                                ),
                                isLeading: true,
                                isHorizontal: false,
                              ),
                            ),
                          );
                        }
                    ),
                  ),
                  _moreFriendsButton()
                ],
              );
            }
          }
          return SizedBox.shrink();
        });
  }

  Row _moreFriendsButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GeneralButton(
          child: LeadingText(
            icon: Icon(PayviceIcons.up_right, color: Colors.black, size: 8,),
            textWidget: Text("More Friends", style: TextStyle(color: Colors.black, fontSize: 12.0),),
            isLeading: false,
          ),
          backgroundColor: Color(0xFFF0F7FF),
          clickListener: () {
            Navigator.pushNamed(
                context, PayviceRouter.payvice_friends
            );
          },
        ),
      ],
    );
  }

  Future<void> _fetchContacts() async {
    var status = await Permission.contacts.status;
    if (status.isGranted) {
      Iterable<Contact> contacts =
      await ContactsService.getContacts(withThumbnails: false);

      String country;

      try {
        country = await FlutterSimCountryCode.simCountryCode;
      } catch(e) {
        country = "NG";
      }

      var phoneContacts = contacts
          .toList()
          .where((element) => element.phones.isNotEmpty)
          .map((contact) => PhoneContact(
          name: contact.displayName,
          number:
          contact.phones.first.value
              .replaceAll("-", "")
              .replaceAll(" ", "")
              .removeFirstZeroInPhoneNumber(
              CountryCode.fromCountryCode(country).dialCode
          )
      ))
          .toList();

      final numbersList = phoneContacts.map((e) => e.number).toSet();
      phoneContacts.retainWhere((x) => numbersList.remove(x.number));

      contactsBloc.fetchContacts(contacts: phoneContacts);
    }
  }
}
