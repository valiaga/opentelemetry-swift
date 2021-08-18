//
//  TelemetrySDK.swift
//  OpenTelemetrySdk
//
//  Created by gordon on 2021/8/16.
//

import Foundation
import OpenTelemetryApi

@objc
@objcMembers
public class TelemetrySDK : NSObject {
    
    public static var instance = TelemetrySDK()
    
    @objc
    public func getTracer(_ instrumentationName: String) -> TelemetryTracer {
        let resource: Resource = OpenTelemetrySDK.instance.tracerProvider.getActiveResource();
        let newResource: Resource = Resource.init(attributes: [
            ResourceAttributes.serviceName.rawValue: AttributeValue.string("iOS"),
            ResourceAttributes.telemetrySdkLanguage.rawValue: AttributeValue.string("Swift"),
            ResourceAttributes.hostName.rawValue: AttributeValue.string("iOS")
        ])
        OpenTelemetrySDK.instance.tracerProvider.updateActiveResource(resource.merging(other: newResource))
        
        return TelemetryTracer(tracer: OpenTelemetrySDK.instance.tracerProvider.get(instrumentationName: instrumentationName))
    }
    
    @objc
    public func addSpanProcessor(_ spanExporter: TelemetrySpanExporter) {
        OpenTelemetrySDK.instance.tracerProvider.addSpanProcessor(SimpleSpanProcessor(spanExporter: BridgeSpanExporter(exporter: spanExporter)))
    }
    
    @objc
    public func activeSpan() -> TelemetrySpan? {
        let span: Span? = OpenTelemetrySDK.instance.contextProvider.activeSpan;
        if span != nil {
            return TelemetrySpan(span: span!)
        } else {
            return nil
        }
    }
    
    @objc
    public func setActiveSpan(_ span: TelemetrySpan) {
        OpenTelemetrySDK.instance.contextProvider.setActiveSpan(span.span)
    }
    
    @objc
    public func removeContextForSpan(_ span: TelemetrySpan) {
        OpenTelemetrySDK.instance.contextProvider.removeContextForSpan(span.span);
    }
    
    @objc
    public func test(tst: String) {
        print("test" + tst)
    }
}

@objc
public class TelemetryTracer : NSObject {
    private var tracer: Tracer
    
    public init(tracer: Tracer) {
        self.tracer = tracer
    }
    
    @objc
    public func spanBuilder(spanName: String) -> TelemetrySpanBuilder {
        return TelemetrySpanBuilder(tracer: self.tracer, spanBuilder: self.tracer.spanBuilder(spanName: spanName))
    }
    
}

@objc
public class TelemetrySpanBuilder: NSObject {
    private var spanBuilder: SpanBuilder
    private var telemetrySpan: TelemetrySpan?
    private var tracer: Tracer
    
    public init(tracer: Tracer, spanBuilder: SpanBuilder) {
        self.tracer = tracer
        self.spanBuilder = spanBuilder
    }
    
    @objc
    public func setParent(_ parent: TelemetrySpan) -> Self {
        self.spanBuilder.setParent(parent.span)
        return self
    }
    
    @objc
    public func setParentWithContext(_ parent: TelemetrySpanContext) -> Self {
        return self
    }
    
    @objc
    public func setNoParent() -> Self {
        spanBuilder.setNoParent()
        return self
    }
    
    @objc
    public func addLink(spanContext: TelemetrySpanContext) -> Self {
        return self
    }
    
    @objc
    public func addLink(spanContext: TelemetrySpanContext, attributes: [String: TelemetryAttributeValue]) -> Self {
        return self
    }
    
    @objc
    public func setAttribute(key: String, stringValue: String) -> Self {
        spanBuilder.setAttribute(key: key, value: stringValue)
        return self
    }
    
    @objc
    public func setAttribute(key: String, intValue: Int) -> Self {
        spanBuilder.setAttribute(key: key, value: intValue)
        return self
    }
    
    @objc
    public func setAttribute(key: String, doubleValue: Double) -> Self {
        spanBuilder.setAttribute(key: key, value: doubleValue)
        return self
    }
    
    @objc
    public func setAttribute(key: String, boolValue: Bool) -> Self {
        spanBuilder.setAttribute(key: key, value: boolValue)
        return self
    }
    
    @objc
    public func setAttribute(key: String, attributeValue: TelemetryAttributeValue) -> Self {
        spanBuilder.setAttribute(key: key, value: attributeValue.getAttribute())
        return self
    }
    
    @objc
    public func setSpanKind(spanKind: TelemetrySpanKind) -> Self {
        spanBuilder.setSpanKind(spanKind: spanKind.kind)
        return self
    }
    
    public func setStartTime(time: NSDate) -> Self {
        spanBuilder.setStartTime(time: Date(timeIntervalSince1970: time.timeIntervalSince1970))
        return self
    }
    
    @objc
    public func startSpan() -> TelemetrySpan? {
        let span = spanBuilder.startSpan()
        return TelemetrySpan(span: span)
    }
    
}

@objc
@objcMembers
public class TelemetrySpan: NSObject {
    fileprivate var span: Span
    
    public init(span: Span) {
        self.span = span
    }
    
    public var kind: TelemetrySpanKind {
        return TelemetrySpanKind(span.kind)
    }
    
    public var context: TelemetrySpanContext {
        return TelemetrySpanContext(spanContext: span.context)
    }
    
    public var isRecording: Bool {
        return span.isRecording
    }
    
    public var status: TelemetryStatus {
        return TelemetryStatus(span.status)
    }
    
    public var name: String {
        return span.name
    }
    
    @objc
    public func setAttribute(key: String, value: TelemetryAttributeValue?) {
        span.setAttribute(key: key, value: value?.getAttribute())
    }
    
    @objc
    public func addEvent(name: String) {
        span.addEvent(name: name);
    }
    
    @objc
    public func addEvent(name: String, timestamp: NSDate) {
        span.addEvent(name: name, timestamp: Date(timeIntervalSince1970: timestamp.timeIntervalSince1970))
    }
    
    @objc
    public func addEvent(name: String, attributes: [String: TelemetryAttributeValue], timestamp: NSDate) {
        var attr: [String: AttributeValue] = [String: AttributeValue]()
        for kv in attributes {
            attr.updateValue(kv.value.getAttribute(), forKey: kv.key)
        }
        
        span.addEvent(name: name, attributes: attr, timestamp: Date(timeIntervalSince1970: timestamp.timeIntervalSince1970))
    }
    
    @objc
    public func end() {
        span.end()
    }
    
    @objc
    public func end(time: NSDate) {
        span.end(time: Date(timeIntervalSince1970: time.timeIntervalSince1970))
    }
    
}


@objc
@objcMembers
public class TelemetrySpanContext: NSObject {
    private var spanContext: SpanContext
    
    fileprivate init(spanContext: SpanContext) {
        self.spanContext = spanContext
    }
    
    public var traceId: String {
        return spanContext.traceId.hexString
    }
    
    public var spanId: String {
        return spanContext.spanId.hexString
    }
    
    public var isRemote: Bool {
        return spanContext.isRemote
    }
    
}

@objc
@objcMembers
public class TelemetryAttributeValue: NSObject {
    private var attribute: AttributeValue
    
    public var value: String
    
    fileprivate init(attribute: AttributeValue) {
        self.attribute = attribute
        self.value = String(attribute.description)
//        switch attribute {
//        case let .string(value):
//            self.value = value
//        case let .bool(value):
//            self.value = value ? "true" : "false"
//        case let .int(value):
//            self.value = String(value)
//        case let .double(value):
//            self.value = String(value)
//
//        }
    }
    
    @objc
    public convenience init(stringValue: String) {
        self.init(attribute: AttributeValue.string(stringValue))
    }
    
    @objc
    public convenience init(boolValue: Bool) {
        self.init(attribute: AttributeValue.bool(boolValue))
    }
    
    @objc
    public convenience init(intValue: Int) {
        self.init(attribute: AttributeValue.int(intValue))
    }
    
    @objc
    public convenience init(doubleValue: Double) {
        self.init(attribute: AttributeValue.double(doubleValue))
    }
    
    fileprivate func getAttribute() -> AttributeValue {
        return self.attribute
    }
    
}

@objc
@objcMembers
public class TelemetrySpanKind: NSObject {
    fileprivate var kind: SpanKind

    public var INTERNAL: TelemetrySpanKind {
        return TelemetrySpanKind(SpanKind.internal)
    }
    
    public var SERVER: TelemetrySpanKind {
        return TelemetrySpanKind(SpanKind.server)
    }
    
    public var CLIENT: TelemetrySpanKind {
        return TelemetrySpanKind(SpanKind.client)
    }
    
    public var PRODUCER: TelemetrySpanKind {
        return TelemetrySpanKind(SpanKind.producer)
    }
    
    public var CONSUMER: TelemetrySpanKind {
        return TelemetrySpanKind(SpanKind.consumer)
    }
    
    fileprivate var name: String
    
    fileprivate init(_ kind: SpanKind) {
        self.kind = kind

        switch kind {
        case .internal:
            name = "internal"
        case .server:
            name = "server"
        case .client:
            name = "client"
        case .producer:
            name = "producer"
        case .consumer:
            name = "consumer"
        }
    }

    fileprivate convenience init(_ name: String) {
        switch name {
        case "internal":
            self.init(.internal)
        case "server":
            self.init(.server)
        case "client":
            self.init(.client)
        case "producer":
            self.init(.producer)
        case "consumer":
            self.init(.consumer)
        default:
            self.init(.internal)
        }
    }
    
}

@objc
@objcMembers
public class TelemetryStatus: NSObject {
    private var status: Status
    fileprivate var name: String
    
    public var OK: TelemetryStatus {
        return TelemetryStatus(.ok)
    }
    
    public var ERROR: TelemetryStatus {
        return TelemetryStatus(.error(description: "error"))
    }
    
    public var UNSET: TelemetryStatus {
        return TelemetryStatus(.unset)
    }
    
    fileprivate init(_ status: Status) {
        self.status = status
        
        switch status {
        case .ok:
            name = "ok"
        case .error(description: _):
            name = "error"
        default:
            name = "unset"
        }
    }
    
    fileprivate convenience init(_ name: String) {
        switch name {
        case "ok":
            self.init(.ok)
        case "error":
            self.init(.error(description: ""))
        default:
            self.init(.unset)
        }
    }
    
}

@objc
public class TelemetrySpanProcessor: NSObject {
    private var spanProcessor: SpanProcessor
    public init(spanProcessor: SpanProcessor) {
        self.spanProcessor = spanProcessor
    }
}


@objc(TelemetrySpanExporter)
public protocol TelemetrySpanExporter: NSObjectProtocol {
    
    func exportTelemetrySpan(spans: [TelemetrySpanData]) -> TelemetrySpanExporterResultCode
    
    func flushTelemetrySpan() -> TelemetrySpanExporterResultCode
    
    func shudownTelemetrySpan()
    
}

@objc
@objcMembers
public class TelemetrySpanData: NSObject {
    private var spanData: SpanData
    
    public init(spanData: SpanData) {
        self.spanData = spanData
    }
    
    public var traceId: String {
        return spanData.traceId.hexString;
    }
    
    public var spanId: String {
        return spanData.spanId.hexString;
    }
    
    // traceFlags
    
    // traceState
    
    public var parentSpanId: String? {
        return spanData.parentSpanId?.hexString;
    }
    
    public var resource: TelemetryResource {
        return TelemetryResource(resource: spanData.resource)
    }

    // instrumentationLibraryInfo
    
    public var name: String {
        return spanData.name;
    }
    
    public var kind: TelemetrySpanKind {
        return TelemetrySpanKind(spanData.kind)
    }
    
    public var startTime: NSDate {
        return NSDate(timeIntervalSince1970: spanData.startTime.timeIntervalSince1970)
    }
    
    public var attributes: [String: TelemetryAttributeValue] {
        var attr: [String: TelemetryAttributeValue] = [String: TelemetryAttributeValue]()
        for kv in spanData.attributes {
            attr.updateValue(TelemetryAttributeValue(attribute: kv.value), forKey: kv.key)
        }
        
        return attr
    }
    
    public var events: [TelemetryEvent] {
        var evts: [TelemetryEvent] = [TelemetryEvent]()
        
        for event in spanData.events {
            evts.append(TelemetryEvent(event))
        }
        
        return evts
    }
    
    // links
    public var links: [TelemetryLink] {
        var links: [TelemetryLink] = [TelemetryLink]()
        
        for kv in spanData.links {
            links.append(TelemetryLink(kv))
        }
        return links
    }
    
    public var status: TelemetryStatus {
        return TelemetryStatus(spanData.status)
    }
    
    public var endTime: NSDate {
        return NSDate(timeIntervalSince1970: spanData.endTime.timeIntervalSince1970)
    }
    
    public var hasRemoteParent: Bool {
        return spanData.hasRemoteParent
    }
    
    public var hasEnded: Bool {
        return spanData.hasEnded
    }
    
    public var totalRecordedEvents: Int {
        return spanData.totalRecordedEvents
    }
    
    public var totalRecordedLinks: Int {
        return spanData.totalRecordedLinks
    }
    
    public var totalAttributeCount: Int {
        return spanData.totalAttributeCount
    }
    
}

@objc
@objcMembers
public class TelemetryLink: NSObject {
    private var link: SpanData.Link
    
    public var context: TelemetrySpanContext {
        return TelemetrySpanContext(spanContext: link.context)
    }
    
    public var attributes: [String: TelemetryAttributeValue] {
        var attr: [String: TelemetryAttributeValue] = [String: TelemetryAttributeValue]()
        for kv in link.attributes {
            attr.updateValue(TelemetryAttributeValue(attribute: kv.value), forKey: kv.key)
        }
        
        return attr
    }
    
    fileprivate init(_ link: SpanData.Link) {
        self.link = link
    }
}

@objc
@objcMembers
public class TelemetryEvent: NSObject {
    private var event: SpanData.Event
    
    public init(_ event: SpanData.Event) {
        self.event = event
    }
    
    @objc
    public convenience init(_ name: String, timestamp: NSDate) {
        let event: SpanData.Event = SpanData.Event(name: name, timestamp: Date(timeIntervalSince1970: timestamp.timeIntervalSince1970))
        self.init(event)
    }
    
    
    public var timestamp: NSDate {
        return NSDate(timeIntervalSince1970: event.timestamp.timeIntervalSince1970)
    }
    
    public var name: String {
        return event.name
    }
    
    public var attributes: [String: TelemetryAttributeValue] {
        var attr: [String: TelemetryAttributeValue] = [String: TelemetryAttributeValue]()
        
        for kv in event.attributes {
            attr.updateValue(TelemetryAttributeValue(attribute: kv.value), forKey: kv.key)
        }

        return attr
    }
}

@objc
@objcMembers
public class TelemetryResource: NSObject {
    private var resource: Resource;
    
    public var attributes: [String: TelemetryAttributeValue] {
        var attr: [String: TelemetryAttributeValue] = [String: TelemetryAttributeValue]()
        for kv in resource.attributes {
            attr.updateValue(TelemetryAttributeValue(attribute: kv.value), forKey: kv.key)
        }
        return attr
    }
    
    fileprivate init(resource: Resource) {
        self.resource = resource;
    }
    
    @objc
    public convenience init(attributes: [String: TelemetryAttributeValue]) {
        var attr: [String: AttributeValue] = [String: AttributeValue]()
        for kv in attributes {
            attr.updateValue(kv.value.getAttribute(), forKey: kv.key)
        }
        
        self.init(resource: Resource(attributes: attr))
    }
    
    @objc
    public static var empty: TelemetryResource {
        return TelemetryResource(resource: Resource.empty)
    }
    
    @objc
    public func merge(other: TelemetryResource) {
        resource.merge(other: other.resource)
    }
    
    @objc
    public func merging(other: TelemetryResource) -> TelemetryResource{
        return TelemetryResource(resource: resource.merging(other: other.resource))
    }
}


@objc
public class TelemetrySpanExporterResultCode: NSObject {
    fileprivate var resultCode: SpanExporterResultCode
    public var code: String
    
    public init(resultCode: SpanExporterResultCode) {
        self.resultCode = resultCode
        if (.success == resultCode) {
            code = "success"
        } else {
            code = "failure"
        }
    }
    
    @objc
    public convenience init(_ code: String) {
        if ("success" == code) {
            self.init(resultCode: .success)
        } else {
            self.init(resultCode: .failure)
        }
    }
    
    
}

public class BridgeSpanExporter: NSObject, SpanExporter, TelemetrySpanExporter {
    private var exporter: TelemetrySpanExporter
    
    public init(exporter: TelemetrySpanExporter) {
        self.exporter = exporter;
    }
    
    
    public func export(spans: [SpanData]) -> SpanExporterResultCode {
        var telemetrySpanData = [TelemetrySpanData]()

        for span in spans {
            telemetrySpanData.append(TelemetrySpanData(spanData: span))
        }
        
        return exportTelemetrySpan(spans: telemetrySpanData).resultCode
    }

    ///Exports the collection of sampled Spans that have not yet been exported.
    public func flush() -> SpanExporterResultCode {
        return flushTelemetrySpan().resultCode
    }
    
    /// Called when TracerSdkFactory.shutdown()} is called, if this SpanExporter is registered
    ///  to a TracerSdkFactory object.
    public func shutdown() {
        self.shudownTelemetrySpan()
    }
    
    public func exportTelemetrySpan(spans: [TelemetrySpanData]) -> TelemetrySpanExporterResultCode {
        return self.exporter.exportTelemetrySpan(spans: spans)
    }
    
    public func flushTelemetrySpan() -> TelemetrySpanExporterResultCode {
        return self.exporter.flushTelemetrySpan()
    }
    
    public func shudownTelemetrySpan() {
        self.exporter.shudownTelemetrySpan()
    }
}
