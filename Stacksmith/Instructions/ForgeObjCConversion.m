//
//  ForgeObjCConversion.m
//  Stacksmith
//
//  Created by Uli Kusterer on 04.06.12.
//  Copyright (c) 2012 Uli Kusterer. All rights reserved.
//

#import "ForgeObjCConversion.h"


void	AppendLEOArrayToDictionary( struct LEOArrayEntry * inEntry, NSMutableDictionary* dict, LEOContext *inContext )
{
	if( inEntry )
	{
		NSString	*	theKey = [NSString stringWithUTF8String: inEntry->key];
		char			strBuf[1024] = { 0 };
		NSString	*	theValue = [NSString stringWithUTF8String: LEOGetValueAsString( &inEntry->value, strBuf, sizeof(strBuf), inContext )];
		[dict setObject: theValue forKey: theKey];	// TODO: Don't always convert to string.
		
		if( inEntry->smallerItem )
			AppendLEOArrayToDictionary( inEntry->smallerItem, dict, inContext );
		if( inEntry->largerItem )
			AppendLEOArrayToDictionary( inEntry->largerItem, dict, inContext );
	}
}


id	WILDObjCObjectFromLEOValue( LEOValuePtr inValue, LEOContext* inContext, LEOValueTypePtr inDesiredType )
{
	id			theObjCValue = nil;
	LEOValuePtr	theArrayValue = LEOFollowReferencesAndReturnValueOfType( inValue, inDesiredType, inContext );
	if( !theArrayValue )
		theArrayValue = LEOFollowReferencesAndReturnValueOfType( inValue, inDesiredType, inContext );
	if( (inDesiredType == &kLeoValueTypeArray || inDesiredType == &kLeoValueTypeArrayVariant) )
	{
		struct LEOArrayEntry	*	theArray = NULL;
		theObjCValue = [NSMutableDictionary dictionary];
		if( theArrayValue )
			theArray = theArrayValue->array.array;
		else
		{
			char		theValueStrBuf[1024] = { 0 };
			char*		theValueStr = LEOGetValueAsString( inValue, theValueStrBuf, sizeof(theValueStrBuf), inContext );
			theArray = LEOCreateArrayFromString( theValueStr, strlen(theValueStr), inContext );	// Make NUL-safe.
		}
		
		AppendLEOArrayToDictionary( theArray, theObjCValue, inContext );
		
		if( !theArrayValue )
			LEOCleanUpArray( theArray, inContext );
	}
	else if( theArrayValue && (inDesiredType == &kLeoValueTypeNumber || inDesiredType == &kLeoValueTypeNumberVariant) )
	{
		theObjCValue = [NSNumber numberWithDouble: theArrayValue->number.number];
	}
	else if( theArrayValue && (inDesiredType == &kLeoValueTypeInteger || inDesiredType == &kLeoValueTypeIntegerVariant) )
	{
		theObjCValue = [NSNumber numberWithLongLong: theArrayValue->integer.integer];
	}
	else if( theArrayValue && (inDesiredType == &kLeoValueTypeBoolean || inDesiredType == &kLeoValueTypeBooleanVariant) )
	{
		theObjCValue = [NSNumber numberWithBool: theArrayValue->boolean.boolean];
	}
	else
	{
		char		theValueStrBuf[1024] = { 0 };
		char*		theValueStr = LEOGetValueAsString( inValue, theValueStrBuf, sizeof(theValueStrBuf), inContext );
		theObjCValue = [NSString stringWithUTF8String: theValueStr];
	}
	
	return theObjCValue;
}


BOOL	WILDObjCObjectToLEOValue( id inValue, LEOValuePtr outValue, LEOContext* inContext )
{
	if( inValue == kCFBooleanTrue || inValue == kCFBooleanFalse )
	{
		LEOInitBooleanValue( outValue, (inValue == kCFBooleanTrue), kLEOInvalidateReferences, inContext );
	}
	else if( [inValue isKindOfClass: [NSString class]] )
	{
		const char*	valueStr = [inValue UTF8String];
		LEOInitStringValue( outValue, valueStr, strlen(valueStr), kLEOInvalidateReferences, inContext );
	}
	else if( [inValue isKindOfClass: [NSNumber class]] )
	{
		if( strcmp([inValue objCType], @encode(long long)) == 0
			|| strcmp([inValue objCType], @encode(NSInteger)) == 0
			|| strcmp([inValue objCType], @encode(int)) == 0
			|| strcmp([inValue objCType], @encode(short)) == 0
			|| strcmp([inValue objCType], @encode(char)) == 0 )
		{
			LEOInitIntegerValue( outValue, [inValue longLongValue], kLEOInvalidateReferences, inContext );
		}
		else
		{
			LEOInitNumberValue( outValue, [inValue doubleValue], kLEOInvalidateReferences, inContext );
		}
	}
	else if( [inValue isKindOfClass: [NSDictionary class]] )
	{
		NSDictionary	*		theDict = inValue;
		struct LEOArrayEntry*	theArray = NULL;
		
		for( NSString* dictKey in theDict )
		{
			id				dictValue = [theDict objectForKey: dictKey];
			union LEOValue	dictValueCopy;
			if( [dictValue isKindOfClass: [NSString class]] )
			{
				const char*	valueStr = [dictValue UTF8String];
				LEOInitStringValue( &dictValueCopy, valueStr, strlen(valueStr), kLEOInvalidateReferences, inContext );
			}
			else if( [dictValue isKindOfClass: [NSNumber class]] )
			{
				LEOInitNumberValue( &dictValueCopy, [dictValue doubleValue], kLEOInvalidateReferences, inContext );
			}
			LEOAddArrayEntryToRoot( &theArray, [dictKey UTF8String], &dictValueCopy, inContext );
			
			LEOCleanUpValue( &dictValueCopy, kLEOInvalidateReferences, inContext );
		}
		LEOInitArrayValue( outValue, theArray, kLEOInvalidateReferences, inContext );
	}
	else
		return NO;
	
	return YES;
}
