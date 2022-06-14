'use strict';

const {Contract} = require('fabric-contract-api');

const contractName = 'net.pharma.drug-registration';

class DrugRegistration extends Contract {

  constructor() {
    super(contractName);
  }

  async instantiate(ctx) {
    console.log('Drug registration contract initialized!');
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

    if(drugName === null || drugName === ''){
      return {
        error: 'Drug Name is required!'
      }
    }

    if(serialNo === null || serialNo === ''){
      return {
        error: 'Serial number of the drug is required!'
      }
    }

    if(mfgDate === null || mfgDate === ''){
      return {
        error: 'Date of manufactuering is required!'
      }
    }

    if(expDate === null || expDate === ''){
      return {
        error: 'Date of expiry is required!'
      }
    }

    if(companyCRN === null || companyCRN === ''){
      return {
        error: 'Company CRN is required!'
      }
    }

    const productId = ctx.stub.createCompositeKey(`${contractName}.product`, [serialNo, drugName]);

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
}
