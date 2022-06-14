'use strict'

const {Contract} = require('fabric-contract-api');

class  PharmanetContract extends Contract {
  constructor() {
    super('net.pharma.pharmanet');
  }

  async instantiate(ctx) {
    console.log('Pharmanet contract initiated');
  }

  /**
   * Register a new company on the network
   * @param ctx - The transaction context object
   * @param crn - Company Registration Number
   * @param name - Name of the company
   * @param location - Location of the company
   * @param orgRole - Manufacturer / Distributor / Retailer / Transporter
   */
  const registerCompany = async (ctx, companyCRN, companyName, location, organisationRole) => {

    const companyId = ctx.stub.createCompositeKey('net.pharma.pharmanet.company', [companyCRN, companyName]);

    let hierarchyKey = 0;

    switch (organisationRole) {
      case 'Manufacturer':
          hierarchyKey = 1;
        break;
      case 'Distributor':
          hierarchyKey = 2;
        break;
      case 'Retailer':
          hierarchyKey = 3;
        break;
      default:
        hierarchyKey = 0
    }

    const newCampanyObj = {
      companyId: companyId,
      name: companyName,
      location: location,
      organisationRole: organisationRole,
      hierarchyKey: hierarchyKey
    }

    const dataBuffer = Buffer.from(JSON.stringify(newCampanyObj));
    await ctx.stub.putState(companyId, dataBuffer);

    return newCampanyObj;
  }

  /**
   * Add a new drug on the network
   * @param ctx - the transaction context object
   * @param drugName - Name of the drug
   * @param serialNo - Serial number of the drug
   * @param mfgDate - Date of manufactuering
   * @param expDate - Date of expiry
   * @param companyCRN - Drug manufacturer's Company Registration Number
   */
  const addDrug = async (ctx, drugName, serialNo, mfgDate, expDate, companyCRN) => {

    const productId = ctx.stub.createCompositeKey('net.pharma.pharmanet.product', [serialNo, drugName]);

    const newProductObj = {
      productId: productId,
      name: drugName,
      manufacturer: "TODO",
      manufacturingDate: mfgDate,
      expiryDate: expDate,
      owner: "TODO",
      shipment: []
    };

    const dataBuffer = Buffer.from(JSON.stringify(newProductObj));
    await ctx.stub.putState(productId, dataBuffer);

    return newProductObj;
  }

  /**
   * Create a new purchase order for a drug on the network
   * @param ctx - The transaction context object
   * @param buyerCRN - Buyer's Company Registration Number
   * @param sellerCRN - Seller's Company Registration Number
   * @param drugName - Name of the drug
   * @param quantity - Number of units ordered
   */
  const createPO = async (ctx, buyerCRN, sellerCRN, drugName, quantity) => {

    //const timestamp = Math.floor(Date.now()/1000);

    const poID = ctx.stub.createCompositeKey('net.pharma.pharmanet.po', [buyerCRN, drugName]);

    const newPurchaseOrderObj = {
      poID: poID,
      drugName: drugName,
      quantity: quantity,
      buyer: "TODO",
      seller: "TODO"
    };

    const dataBuffer = Buffer.from(JSON.stringify(newPurchaseOrderObj));
    await ctx.stub.putState(poID, dataBuffer);

    return newPurchaseOrderObj;
  }

  /**
   * Creates a new shipment on the network
   * @param ctx - the transaction context object
   * @param buyerCRN - buyer's Company Registration Number
   * @param drugName - Name of the drug
   * @param listOfAssets - List of composite keys of assets
   */
  const createShipment = async (ctx, buyerCRN, drugName, listOfAssets, transporterCRN) => {

    const poID = ctx.stub.createCompositeKey('net.pharma.pharmanet.po', [buyerCRN, drugName]);

    const dataBuffer = await ctx.stub
     .getState(poID)
     .catch(err => console.log(err));

    if(!dataBuffer || dataBuffer.length === 0){
      throw new Error(`${poID} does not exist`);
    }

    const poObj = JSON.parse(dataBuffer.toString());

    if(listOfAssets.length !== poObj.quantity){
      throw new Error(`Quantity mismatch`);
    }

    // const promises = [];
    // listOfAssets.forEach((assetId) => {
    //    const promise = new Promise((resolve, reject) => {
    //      ctx.stub.getState(assetId);
    //      resolve();
    //    });
    //    promises.push(promise);
    // });
    const shipmentID = ctx.stub.createCompositeKey('net.pharma.pharmanet.shipment', [buyerCRN, drugName]);

    const newShipmentObj = {
      shipmentID: shipmentID,
      creator: ctx.clientIdentity.getID(),
      assets: listOfAssets,
      transporter: "TODO",
      status: "in-transit"
    }

    const dataBuffer = Buffer.from(JSON.stringify(newShipmentObj));
    await ctx.stub.putState(shipmentID, dataBuffer);

    return newShipmentObj;
  }

  /**
   * Update existing shipment on the network
   * @param ctx - the transaction context object
   * @param buyerCRN - Buyer's company registration Number
   * @param drugName - Name of the drug
   * @param transporterCRN - Transporter's company registration number
   */
  const updateShipment = async (ctx, buyerCRN, drugName, transporterCRN) => {

    const shipmentID = ctx.stub.createCompositeKey('net.pharma.pharmanet.shipment', [buyerCRN, drugName]);
    
  }

  const retailDrug = async (ctx, drugName, serialNo, retailerCRN, customerAadhar) => {

  }

  const viewHistory = async (ctx, drugName, serialNo) => {

  }

  /**
   * Get drug details
   */
  const viewDrugCurrentState = async (ctx, drugName, serialNo) => {

    const productId = ctx.stub.createCompositeKey('net.pharma.pharmanet.product', [serialNo, drugName]);

    const dataBuffer = await ctx.stub
      .getState(productId)
      .catch(err => console.log(err));

    return JSON.parse(dataBuffer.toString());

  }
}


module.exports = PharmanetContract;
