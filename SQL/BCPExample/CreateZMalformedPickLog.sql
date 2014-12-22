USE x3v6
GO
CREATE TABLE [ECCPROD].[ZMalformedPickLog](
	[ID] [int] NOT NULL,
	[ItemReference] [nvarchar](40) NULL,
	[PickTicket] [nvarchar](40) NULL,
	[SalesOrderNumber] [nvarchar](40) NULL,
	[QTYSTU] [numeric](28, 13) NULL,
	[ALLQTY] [numeric](28, 13) NULL,
	[DeliveryFlag] [varchar](20) NULL,
	[StockSTOFCY] [nvarchar](10) NULL,
	[StockSTOCOU] [numeric](11, 1) NULL,
	[StockLot] [nvarchar](34) NULL,
	[StockLoc] [nvarchar](20) NULL,
	[StockLOCTYP] [nvarchar](10) NULL,
	[StockQTYPCU] [numeric](28, 13) NULL,
	[StockQTYSTU] [numeric](28, 13) NULL,
	[StockQTYSTUACT] [numeric](28, 13) NULL,
	[StockCUMALLQTY] [numeric](28, 13) NULL,
	[StockCUMWIPQTY] [numeric](28, 13) NULL,
	[StockCUMWIPQTA] [numeric](28, 13) NULL,
	[StockLASRCPDAT] [datetime] NULL,
	[StowipWIPQTY] [numeric](28, 13) NULL,
	[StowipWIPQTA] [numeric](28, 13) NULL,
	[StowipCREDAT] [datetime] NULL,
	[StowipCREUSR] [nvarchar](10) NULL,
	[StoallCreateUser] [nvarchar](10) NULL,
	[StoallCreateDate] [datetime] NULL,
	[StoallUpdateUser] [nvarchar](10) NULL,
	[StoallUpdateDate] [datetime] NULL,
	[StoallLocationShortage] [nvarchar](50) NULL,
	[StoallStockQuantity] [numeric](28, 13) NULL,
	[StoallActiveStockQuantity] [numeric](28, 13) NULL,
	[StoallSequence] [int] NULL,
	[StoallShortageStatus] [nvarchar](6) NULL,
	[StoallEntryType] [tinyint] NULL,
	[HeaderCreateDate] [datetime] NULL,
	[HeaderCreateUser] [nvarchar](10) NULL,
	[HeaderUpdateDate] [datetime] NULL,
	[HeaderUpdateUser] [nvarchar](10) NULL,
	[DetailCreateDate] [datetime] NULL,
	[DetailCreateUser] [nvarchar](10) NULL,
	[DetailUpdateDate] [datetime] NULL,
	[DetailUpdateUser] [nvarchar](10) NULL,
	[HeaderRowID] [int] NULL,
	[DetailRowID] [int] NULL,
	[YDOCK_0] [nvarchar](40) NULL,
	[InsertGUID] [uniqueidentifier] NULL,
	[LogDate] [datetime] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


