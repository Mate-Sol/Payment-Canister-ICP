import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Map "mo:base/HashMap";
import Error "mo:base/Error";
import List "mo:base/List";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";

actor Payment {
  type Payment = {
    Type : Text;
    InvoiceId : Text;
    MongoId : Text;
    PaymentId : Text;
    // vendorId : Text;
    VendorEmail : Text;
    VendorMobileNumberHash : Text;
    VendorEmailHash : Text;
    VendorMobileNumber : Text;
    CurrencyCode : Text;
    PaidAmount : Text;
    // ClientLastName : Text;
    PaymentType : Text;
    ReceiptUrl : Text;
    Date : Text;
    TimeStamp : Int;
    PaymentGateway : Text;
    NetAmtFC : Text;
    TxnHash : Text;
  };
  type QueryResult = {
    Key : Text;
    Record : ?Payment;
  };
  // type History = {
  //     Record : ;
  // };

  private stable var mapEntries : [(Text, Payment)] = [];
  var map = Map.HashMap<Text, Payment>(0, Text.equal, Text.hash);
  private stable var historyEntries : [(Text, [Payment])] = [];
  var history = Map.HashMap<Text, Buffer.Buffer<Payment>>(0, Text.equal, Text.hash);

  public func CreatePayment(mongoId : Text, invoiceId : Text, paymentId : Text,  currencyCode : Text, paidAmount : Text, paymentType : Text, receiptUrl : Text, paymentGateway : Text, date : Text, netAmtFC : Text, vendorEmail : Text, vendorMobileNumber : Text, vendorEmailHash : Text, vendorMobilehash : Text, txnHash : Text) : async Text {

    switch (map.get(mongoId)) {
      case (null) {
        let payment : Payment = {
          Type = "InvoicePayment";
          InvoiceId = invoiceId;
          MongoId = mongoId;
          PaymentId = paymentId;
          // vendorId = vendorId;
          VendorEmail = vendorEmail;
          VendorMobileNumberHash = vendorMobilehash;
          VendorEmailHash = vendorEmailHash;
          VendorMobileNumber = vendorMobileNumber;
          CurrencyCode = currencyCode;
          PaidAmount = paidAmount;
          PaymentType = paymentType;
          ReceiptUrl = receiptUrl;
          Date = date;
          TimeStamp = Time.now();
          PaymentGateway = paymentGateway;
          NetAmtFC = netAmtFC;
          TxnHash = txnHash;

        };

        map.put(mongoId, payment);
        var a = Buffer.Buffer<Payment>(0);
        a.add(payment);
        history.put(mongoId, a);
        return "payment invoice created";
      };
      case (?value) {
        return "payment invoice allready exist";
      };
    };

  };

  public query func QueryPaymentInvoice(id : Text) : async ?Payment {
    map.get(id);
  };

  public query func QueryAllPaymentInvoices() : async [(Text, Payment)] {
    var tempArray : [(Text, Payment)] = [];
    tempArray := Iter.toArray(map.entries());

    return tempArray;
  };

  public query func GetPaymentInvoiceHistory(mongoId : Text) : async [Payment] {
    switch (history.get(mongoId)) {
      case (?x) {
        return Buffer.toArray<Payment>(x);
      };
      case (null) {
        return [];
      };
    };

  };

  public query func QueryInvoicesBasedvendorEmail(emailHash : Text) : async [Payment] {
    var b = Buffer.Buffer<Payment>(2);

    // var buffer: Buffer.T<Invoice> = Buffer.empty<Invoice>();
    for (invoice in map.entries()) {
      if (invoice.1.VendorEmailHash == emailHash) {
        b.add(invoice.1);
      };
    };
    return Buffer.toArray<Payment>(b);

  };

  public query func QueryInvoicesByvendorMobileNumber(vendorNumber : Text) : async [Payment] {
    var b = Buffer.Buffer<Payment>(2);

    for (invoice in map.entries()) {
      if (invoice.1.VendorMobileNumberHash == vendorNumber) {
        b.add(invoice.1);
      };
    };

    return Buffer.toArray<Payment>(b);
  };

  public query func QueryInvoiceBypaymentId(paymentId : Text) : async [Payment] {
    var b = Buffer.Buffer<Payment>(2);

    // var buffer: Buffer.T<Invoice> = Buffer.empty<Invoice>();
    for (invoice in map.entries()) {
      if (invoice.1.PaymentId == paymentId) {
        b.add(invoice.1);
      };
    };
    return Buffer.toArray<Payment>(b);

  };

  public query func QueryInvoiceByinvoiceId(invoiceId : Text) : async [Payment] {
    var b = Buffer.Buffer<Payment>(2);

    for (invoice in map.entries()) {
      if (invoice.1.InvoiceId == invoiceId) {
        b.add(invoice.1);
      };
    };

    return Buffer.toArray<Payment>(b);
  };

  public query func QueryInvoiceByHash(txnHash : Text) : async [Payment] {
    var b = Buffer.Buffer<Payment>(2);

    // var buffer: Buffer.T<Invoice> = Buffer.empty<Invoice>();
    for (invoice in map.entries()) {
      if (invoice.1.TxnHash == txnHash) {
        b.add(invoice.1);
      };
    };
    return Buffer.toArray<Payment>(b);

  };

  public query func QueryInvoiceBytimeStamp(timeStamp : Int) : async [Payment] {
    var b = Buffer.Buffer<Payment>(0);

    for (invoice in map.entries()) {
      if (invoice.1.TimeStamp == timeStamp) {
        b.add(invoice.1);
      };
    };

    return Buffer.toArray<Payment>(b);
  };
  public query func QueryInvoiceByType(invoiceType : Text) : async [Payment] {
    var b = Buffer.Buffer<Payment>(0);

    for (invoice in map.entries()) {
      if (invoice.1.Type == invoiceType) {
        b.add(invoice.1);
      };
    };

    return Buffer.toArray<Payment>(b);
  };

  system func preupgrade() {
    mapEntries := Iter.toArray(map.entries());
    let Entries = Iter.toArray(history.entries());
    var data = Map.HashMap<Text, [Payment]>(0, Text.equal, Text.hash);

    for (x in Iter.fromArray(Entries)) {
      data.put(x.0, Buffer.toArray<Payment>(x.1));
    };
    historyEntries := Iter.toArray(data.entries());

  };
  system func postupgrade() {
    map := HashMap.fromIter<Text, Payment>(mapEntries.vals(), 1, Text.equal, Text.hash);
    let his = HashMap.fromIter<Text, [Payment]>(historyEntries.vals(), 1, Text.equal, Text.hash);
    let Entries = Iter.toArray(his.entries());
    for (x in Iter.fromArray(Entries)) {
      history.put(x.0, Buffer.fromArray<Payment>(x.1));
    };

  };
};
