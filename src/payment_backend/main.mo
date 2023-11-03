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
    PaymentID : Text;
    VendorId : Text;
    VendorEmail : Text;
    VendorMobileNumberHash : Text;
    VendorEmailHash : Text;
    VendorMobileNumber : Text;
    CurrencyCode : Text;
    PaidAmount : Text;
    ClientLastName : Text;
    PaymentType : Text;
    ReceiptUrl : Text;
    Date : Int;
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

  public func CreatePayment(mongoid : Text, invoiceid : Text, clientLastname : Text, paymentID : Text, vendorId : Text, currencyCode : Text, paidAmount : Text, paymentType : Text, receiptUrl : Text, paymentGateway : Text, timeStamp : Text, netAmtFC : Text, vendorEmail : Text, vendorMobileNumber : Text, vendorEmailhash : Text, vendorMobilehash : Text, txnHash : Text) : async Text {

    switch (map.get(mongoid)) {
      case (null) {
        let payment : Payment = {
          Type = "Invoice";
          InvoiceId = invoiceid;
          MongoId = mongoid;
          PaymentID = paymentID;
          VendorId = vendorId;
          VendorEmail = vendorEmail;
          VendorMobileNumberHash = vendorMobileNumber;
          VendorEmailHash = vendorEmailhash;
          VendorMobileNumber = vendorMobileNumber;
          CurrencyCode = currencyCode;
          PaidAmount = paidAmount;
          ClientLastName = clientLastname;
          PaymentType = paymentType;
          ReceiptUrl = receiptUrl;
          Date = Time.now();
          TimeStamp = Time.now();
          PaymentGateway = paymentGateway;
          NetAmtFC = netAmtFC;
          TxnHash = txnHash;

        };

        map.put(mongoid, payment);
        var a = Buffer.Buffer<Payment>(0);
        a.add(payment);
        history.put(mongoid, a);
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

  public query func QueryInvoicesBasedVendorEmail(emailHash : Text) : async [Payment] {
    var b = Buffer.Buffer<Payment>(2);

    // var buffer: Buffer.T<Invoice> = Buffer.empty<Invoice>();
    for (invoice in map.entries()) {
      if (invoice.1.VendorEmailHash == emailHash) {
        b.add(invoice.1);
      };
    };
    return Buffer.toArray<Payment>(b);

  };

  public query func QueryInvoicesByVendorMobileNumber(vendorNumber : Text) : async [Payment] {
    var b = Buffer.Buffer<Payment>(2);

    for (invoice in map.entries()) {
      if (invoice.1.VendorMobileNumberHash == vendorNumber) {
        b.add(invoice.1);
      };
    };

    return Buffer.toArray<Payment>(b);
  };

  public query func QueryInvoiceByPaymentId(paymentID : Text) : async [Payment] {
    var b = Buffer.Buffer<Payment>(2);

    // var buffer: Buffer.T<Invoice> = Buffer.empty<Invoice>();
    for (invoice in map.entries()) {
      if (invoice.1.PaymentID == paymentID) {
        b.add(invoice.1);
      };
    };
    return Buffer.toArray<Payment>(b);

  };

  public query func QueryInvoiceByInvoiceId(invoiceid : Text) : async [Payment] {
    var b = Buffer.Buffer<Payment>(2);

    for (invoice in map.entries()) {
      if (invoice.1.InvoiceId == invoiceid) {
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

  public query func QueryInvoiceByTimeStamp(timeStamp : Int) : async [Payment] {
    var b = Buffer.Buffer<Payment>(2);

    for (invoice in map.entries()) {
      if (invoice.1.TimeStamp == timeStamp) {
        b.add(invoice.1);
      };
    };

    return Buffer.toArray<Payment>(b);
  };
  public query func QueryInvoiceByType(invoiceType : Text) : async [Payment] {
    var b = Buffer.Buffer<Payment>(2);

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
