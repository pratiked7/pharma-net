'use strict';

const {Contract} = require('fabric-contract-api');

const contractName = 'net.pharma.company-registration';

class CompanyRegistration extends Contract {

  constructor() {
    super(contractName);
  }

  async instantiate(ctx){
    console.log("Company registration contract initiated");
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

    if(companyCRN === null || companyCRN === ''){
      return {
        error: 'Company CRN is required!'
      };
    }

    if(companyName === null || companyName === ''){
      return {
        error: 'Company name is required!'
      };
    }

    const companyId = ctx.stub.createCompositeKey(
      `${contractName}.company`,
      [companyCRN, companyName]);

    try {

      const companyDetailBuffer = await ctx.stub
        .getState(companyId)
        .catch(err => console.log(err));

      if (!companyDetailBuffer || companyDetailBuffer.length === 0){

        if(organisationRole !== null && organisationRole !== ''){

          if(organisationRole === 'Manufacturer' ||
             organisationRole === 'Distributor' ||
             organisationRole === 'Retailer') {

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

             } else {
               return {
                 error: 'Organisation role is wrong!'
               }
             }
        } else {
          return {
            error: 'Organisation role is required!'
          };
        }

      } else {
        console.log('This company has been registered already!');
        return null;
      }

    } catch (e) {
      return {
        error: `Something went wrong! ${e}`
      }
    }

  }
}

module.exports = CompanyRegistration;
