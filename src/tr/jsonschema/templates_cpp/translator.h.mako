<%doc>
Copyright (c) 2016 FiftyThree, Inc.
</%doc>
<%inherit file="base.mako" />
<%namespace name="base" file="base.mako" />
<%block name="code">
#pragma once

#include <json11/json11.hpp>

#include "Core/Memory.h"
#include "SyncClient/NativeAction.h"
#include "SyncClient/Schema/ModelAction.h"
% if class_names:
% for class_name in class_names:
#include "SyncClient/Schema/${class_name}.h"
% endfor
% endif

BEGIN_SYNC_NAMESPACE

class GenericMessageTranslatorDelegate
{
public:
    ALIAS_PTR_TYPES(GenericMessageTranslatorDelegate);

protected:
    ~GenericMessageTranslatorDelegate() {}

public:
    virtual void DispatchRemoteAction(const schema::ClientPresenceUpdateAction::Ptr &action) = 0;

    virtual void DispatchRemoteAction(const schema::TeamPresenceSnapshotAction::Ptr &action) = 0;

    virtual void DispatchRemoteAction(const schema::ModelAction::Ptr &action) = 0;
};

#pragma mark -

// This class is intended to eventually supercede SyncEngineMessageTranslator.
//
// Its contents will eventually be code-generated from the JSON schemas.
class GenericMessageTranslator
{
private:
    GenericMessageTranslator() {}

public:
    // Until GenericMessageTranslator completely supercedes SyncEngineMessageTranslator,
    // this method returns true IFF it was able to translate and dispatch the message.
    static bool TranslateAndDispatchJSONMessage(const json11::Json &json,
                                                const GenericMessageTranslatorDelegate::Ptr &delegate)
    {
        DebugAssert(delegate);

        // We code generate this file so that the contents of this cascading if-else statement
        // can be derived from the JSON schemas.
        if (!json["type"].is_string()) {
            PROD_MLOG_DEBUG(FTLogSyncClient, "Message missing type: %s", json.dump().c_str());
% if class_names:
% for class_name in class_names:
        } else if (json["type"] == "${class_name}") {
            const auto message = std::make_shared<schema::${class_name}>(json);
            if (message->is_valid()) {
                delegate->DispatchRemoteAction(message);

                return true;
            } else {
                FTFail("Invalid ${class_name} message: %s", message->get_validity_error().c_str());
            }
% endfor
% endif
        } else {
            // TODO: Once GenericMessageTranslator replaces SyncEngineMessageTranslator,
            // this block should assert, since an unexpected message was received.
            // FTFail("Un-implemented action");

            PROD_MLOG_DEBUG(FTLogSyncClient, "Message has unknown type: %s", json.dump().c_str());
        }

        return false;
    }
};

END_SYNC_NAMESPACE

</%block>
